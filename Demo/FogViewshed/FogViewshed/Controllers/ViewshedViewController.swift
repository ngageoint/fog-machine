import UIKit
import MapKit
import FogMachine
import SwiftEventBus

class ViewshedViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UITabBarControllerDelegate {

    // MARK: Class Variables

    var model:ObserverFacade = ObserverFacade()
    // Only used for segue from ObserverSettings
    var settingsObserver:Observer = Observer()
    let locationManager:CLLocationManager = CLLocationManager()

    // MARK: IBOutlets

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapTypeSelector: UISegmentedControl!
    @IBOutlet weak var logBox: UITextView!
    @IBOutlet weak var mapViewProportionalHeight: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tabBarController!.delegate = self
        self.mapView.showsUserLocation = true
        self.mapView.tintColor = UIColor.blueColor()
        self.mapView.delegate = self
        let onLongPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(ViewshedViewController.onLongPress(_:)))
        onLongPressGesture.minimumPressDuration = 0.2
        self.mapView.addGestureRecognizer(onLongPressGesture)

        // TODO: What should happen when the viewshed is done?
        SwiftEventBus.onMainThread(self, name: ViewshedEventBusEvents.viewshedComplete) { result in
            ActivityIndicator.hide(success: true, animated: true)
        }
        
        // log any info from Fog Machine to our textbox
        SwiftEventBus.onMainThread(self, name: ViewshedEventBusEvents.onLog) { result in
            let format:String = result.object as! String
            self.ViewshedLog(format)
        }

        SwiftEventBus.onMainThread(self, name: ViewshedEventBusEvents.drawGridOverlay) { result in
            let gridOverlay:GridOverlay = result.object as! GridOverlay
            self.mapView.addOverlay(gridOverlay)
        }

        SwiftEventBus.onMainThread(self, name: ViewshedEventBusEvents.addObserverPin) { result in
            let observer:Observer = result.object as! Observer
            self.addObserver(observer)
        }

        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        let status = CLLocationManager.authorizationStatus()
        if (status == .NotDetermined || status == .Denied || status == .Restricted)  {
            self.locationManager.requestAlwaysAuthorization()
        } else {
            self.locationManager.startUpdatingLocation()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        setupMapLog()
        drawObservers()
        drawDataRegions()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    // MARK: - TabBarController Delegates

    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        //If the selected viewController is the main mapViewController
        if viewController == tabBarController.viewControllers?[1] {
            drawDataRegions()
        }
    }

    // MARK: Location Delegate Methods

    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if (status == .AuthorizedWhenInUse || status == .AuthorizedAlways) {
            self.locationManager.startUpdatingLocation()
        }
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locationManager.stopUpdatingLocation()
        // most recent is at the end
        let location:CLLocation = locations.last!
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
        self.mapView?.centerCoordinate = location.coordinate
        self.mapView.setRegion(region, animated: true)
    }

    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        NSLog("Error: " + error.localizedDescription)
    }

    private func drawObservers() {
        mapView.removeAnnotations(mapView.annotations)
        
        for observer in model.getObservers() {
            drawPin(observer)
        }
    }

    private func drawDataRegions() {
        var dataRegionOverlays = [MKOverlay]()
        for overlay in mapView.overlays {
            if overlay is MKPolygon {
                dataRegionOverlays.append(overlay)
            }
        }
        mapView.removeOverlays(dataRegionOverlays)
        
        for hgtFile in HGTManager.getLocalHGTFiles() {
            self.mapView.addOverlay(hgtFile.getBoundingBox().asMKPolygon())
        }
    }

    private func drawPin(observer: Observer) {
        let dropPin = MKPointAnnotation()
        dropPin.coordinate = observer.position
        dropPin.title = observer.description
        mapView.addAnnotation(dropPin)
    }
    
    
    private func redraw() {
        drawObservers()
        drawDataRegions()
    }
    
    private func addObserver(observer:Observer) {
        if(model.add(observer)) {
            drawPin(observer)
        }
    }

    func onLongPress(gestureRecognizer: UIGestureRecognizer) {
        if (gestureRecognizer.state == UIGestureRecognizerState.Began) {
            if(HGTManager.getLocalHGTFileByName(HGTFile.coordinateToFilename(mapView.convertPoint(gestureRecognizer.locationInView(mapView), toCoordinateFromView: mapView), resolution: Srtm.SRTM3_RESOLUTION)) != nil) {
                let newObserver = Observer()
                newObserver.position = mapView.convertPoint(gestureRecognizer.locationInView(mapView), toCoordinateFromView: mapView)
                addObserver(newObserver)
            } else {
                var style = ToastStyle()
                style.messageColor = UIColor.redColor()
                style.backgroundColor = UIColor.whiteColor()
                style.messageFont = UIFont(name: "HelveticaNeue", size: 16)
                self.view.makeToast("No elevation data here.  Go download some.", duration: 1.5, position: .Center, style: style)
                return
            }
        }
    }

    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        var polygonView:MKPolygonRenderer? = nil
        if overlay is MKPolygon {
            polygonView = MKPolygonRenderer(overlay: overlay)
            polygonView!.lineWidth = 0.5
            polygonView!.fillColor = UIColor.yellowColor().colorWithAlphaComponent(0.08)
            polygonView!.strokeColor = UIColor.redColor().colorWithAlphaComponent(0.6)
        } else if overlay is GridOverlay {
            let imageToUse = (overlay as! GridOverlay).image
            let overlayView = GridOverlayView(overlay: overlay, overlayImage: imageToUse)

            return overlayView
        }

        return polygonView!
    }

    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {

        var view:MKPinAnnotationView? = nil
        let identifier = "pin"
        if (annotation is MKUserLocation) {
            //if annotation is not an MKPointAnnotation (eg. MKUserLocation),
            //return nil so map draws default view for it (eg. blue bubble)...
            return nil
        }
        if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? MKPinAnnotationView {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view!.canShowCallout = true
            view!.calloutOffset = CGPoint(x: -5, y: 5)

            let image = UIImage(named: "Viewshed")
            let button = UIButton(type: UIButtonType.DetailDisclosure)
            button.setImage(image, forState: UIControlState.Normal)

            view!.leftCalloutAccessoryView = button as UIView
            view!.rightCalloutAccessoryView = UIButton(type: UIButtonType.DetailDisclosure) as UIView
        }

        return view
    }

    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let selectedObserver = retrieveObserver((view.annotation?.coordinate)!) {
            if control == view.rightCalloutAccessoryView {
                performSegueWithIdentifier("observerSettings", sender: selectedObserver)
            } else if control == view.leftCalloutAccessoryView {
                self.initiateFogViewshed(selectedObserver)
            }
        } else {
            print("Observer not found for \((view.annotation?.coordinate)!)")
        }
    }

    private func setupMapLog() {
        var multiplier:CGFloat = 1.0
        if(NSUserDefaults.standardUserDefaults().boolForKey("isLogShown")) {
            multiplier = 0.8
        }
        
        // change the constraint multiplier
        let newMapViewProportionalHeight = NSLayoutConstraint(
            item: mapViewProportionalHeight.firstItem,
            attribute: mapViewProportionalHeight.firstAttribute,
            relatedBy: mapViewProportionalHeight.relation,
            toItem: mapViewProportionalHeight.secondItem,
            attribute: mapViewProportionalHeight.secondAttribute,
            multiplier: multiplier,
            constant: mapViewProportionalHeight.constant)

        newMapViewProportionalHeight.priority = mapViewProportionalHeight.priority

        NSLayoutConstraint.deactivateConstraints([mapViewProportionalHeight])
        NSLayoutConstraint.activateConstraints([newMapViewProportionalHeight])

        mapViewProportionalHeight = newMapViewProportionalHeight
    }

    func retrieveObserver(coordinate: CLLocationCoordinate2D) -> Observer? {
        var foundObserver: Observer? = nil

        for observer in model.getObservers() {
            if coordinate.latitude == observer.position.latitude && coordinate.longitude == observer.position.longitude {
                foundObserver = observer
                break
            }
        }
        return foundObserver
    }


    // MARK: Viewshed

    func initiateFogViewshed(observer: Observer) {
        ActivityIndicator.show("Calculating Viewshed")
        self.ViewshedLog("Running viewshed")
        (FogMachine.fogMachineInstance.getTool() as! ViewshedTool).createWorkViewshedObserver = observer
        (FogMachine.fogMachineInstance.getTool() as! ViewshedTool).createWorkViewshedAlgorithmName = ViewshedAlgorithmName.FranklinRay
        FogMachine.fogMachineInstance.execute()
    }

    // MARK: IBActions

    @IBAction func mapTypeChanged(sender: AnyObject) {
        let mapType = MapType(rawValue: mapTypeSelector.selectedSegmentIndex)
        switch (mapType!) {
        case .Standard:
            mapView.mapType = MKMapType.Standard
        case .Hybrid:
            mapView.mapType = MKMapType.Hybrid
        case .Satellite:
            mapView.mapType = MKMapType.Satellite
        }
    }

    @IBAction func focusToCurrentLocation(sender: AnyObject) {
        self.locationManager.startUpdatingLocation()
    }
    
    // MARK: Segue

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "observerSettings" {
            let viewController: ObserverSettingsViewController = segue.destinationViewController as! ObserverSettingsViewController
            viewController.originalObserver = sender as! Observer?
        }
    }

    @IBAction func applyOptions(segue: UIStoryboardSegue) {

    }

    @IBAction func removeViewshedFromSettings(segue: UIStoryboardSegue) {
        mapView.removeOverlays(mapView.overlays)
        redraw()
    }

    @IBAction func removePinFromSettings(segue: UIStoryboardSegue) {
        redraw()
    }

    @IBAction func deleteAllPins(segue: UIStoryboardSegue) {
        model.clearEntity()
        redraw()
    }

    @IBAction func runSelectedFogViewshed(segue: UIStoryboardSegue) {
        self.initiateFogViewshed(self.settingsObserver)
    }

    @IBAction func drawElevationData(segue: UIStoryboardSegue) {
        ElevationTool(elevationObserver: self.settingsObserver).drawElevationData()
    }
    
    @IBAction func applyObserverSettings(segue:UIStoryboardSegue) {
        if segue.sourceViewController.isKindOfClass(ObserverSettingsViewController) {
            mapView.removeAnnotations(mapView.annotations)
            drawObservers()
        }
    }

    // MARK: Logging

    func ViewshedLog(format: String, writeToDebugLog:Bool = false, clearLog: Bool = false) {
        if(writeToDebugLog) {
            NSLog(format)
        }
        dispatch_async(dispatch_get_main_queue()) {
            if(clearLog) {
                self.logBox.text = ""
            }
            let dateFormater = NSDateFormatter()
            dateFormater.dateFormat = NSDateFormatter.dateFormatFromTemplate("HH:mm:ss.SSS", options: 0, locale:  NSLocale.currentLocale())
            let currentTimestamp:String = dateFormater.stringFromDate(NSDate());
            dispatch_async(dispatch_get_main_queue()) {
                self.logBox.text.appendContentsOf(currentTimestamp + " " + format + "\n")
                self.logBox.scrollRangeToVisible(NSMakeRange(self.logBox.text.characters.count - 1, 1));
            }
        }
    }

}
