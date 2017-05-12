import UIKit
import MapKit
import FogMachine
import SwiftEventBus
import Toast_Swift
import EZLoadingActivity
import SceneKit


class ViewshedViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UITabBarControllerDelegate {

    // MARK: Class Variables

    var model: ObserverFacade = ObserverFacade()
    // Only used for segue from ObserverSettings
    var settingsObserver: Observer = Observer()
    let locationManager: CLLocationManager = CLLocationManager()
    var viewshedSceneView: SCNView = SCNView()
    var viewshedResultImage: [String: UIImage] = [:]
    
    // MARK: IBOutlets

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapTypeSelector: UISegmentedControl!
    @IBOutlet weak var logBox: UITextView!
    @IBOutlet weak var mapViewProportionalHeight: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tabBarController!.delegate = self
        self.mapView.showsUserLocation = true
        self.mapView.tintColor = UIColor.blue
        self.mapView.delegate = self
        let onLongPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(ViewshedViewController.onLongPress(_:)))
        onLongPressGesture.minimumPressDuration = 0.2
        self.mapView.addGestureRecognizer(onLongPressGesture)

        // TODO: What should happen when the viewshed is done?
        _ = SwiftEventBus.onMainThread(self, name: ViewshedEventBusEvents.viewshedComplete) { result in
            _ = EZLoadingActivity.hide(true, animated: false)
        }
        
        // log any info from Fog Machine to our textbox
        _ = SwiftEventBus.onMainThread(self, name: ViewshedEventBusEvents.onLog) { result in
            let format: String = result.object as! String
            self.ViewshedLog(format)
        }

        _ = SwiftEventBus.onMainThread(self, name: ViewshedEventBusEvents.drawGridOverlay) { result in
            let gridOverlay: GridOverlay = result.object as! GridOverlay
            let location: CGPoint = CGPoint.init(x: gridOverlay.coordinate.latitude, y: gridOverlay.coordinate.longitude)
            self.viewshedResultImage[String(describing: location)] = gridOverlay.image
            self.mapView.add(gridOverlay)
        }

        _ = SwiftEventBus.onMainThread(self, name: ViewshedEventBusEvents.viewshed3d) { result in
            let elevationDataGrid: DataGrid = result.object as! DataGrid
            self.display3dViewshed(elevationDataGrid)
        }

        _ = SwiftEventBus.onMainThread(self, name: ViewshedEventBusEvents.addObserverPin) { result in
            let observer: Observer = result.object as! Observer
            self.addObserver(observer)
        }

        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        let status = CLLocationManager.authorizationStatus()
        if (status == .notDetermined || status == .denied || status == .restricted)  {
            self.locationManager.requestAlwaysAuthorization()
        } else {
            self.locationManager.startUpdatingLocation()
        }

    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupMapLog()
        drawObservers()
        drawDataRegions()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    // MARK: - TabBarController Delegates

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        //If the selected viewController is the main mapViewController
        if viewController == tabBarController.viewControllers?[1] {
            drawDataRegions()
            //Remove the viewshed 3D scene
            self.viewshedSceneView.removeFromSuperview()
        }
    }

    // MARK: Location Delegate Methods

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if (status == .authorizedWhenInUse || status == .authorizedAlways) {
            self.locationManager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locationManager.stopUpdatingLocation()
        // most recent is at the end
        let location:CLLocation = locations.last!
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
        self.mapView?.centerCoordinate = location.coordinate
        self.mapView.setRegion(region, animated: true)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        NSLog("Error: " + error.localizedDescription)
    }

    fileprivate func drawObservers() {
        mapView.removeAnnotations(mapView.annotations)
        
        for observer in model.getObservers() {
            drawPin(observer)
        }
    }

    fileprivate func drawDataRegions() {
        var dataRegionOverlays = [MKOverlay]()
        for overlay in mapView.overlays {
            if overlay is MKPolygon {
                dataRegionOverlays.append(overlay)
            }
        }
        mapView.removeOverlays(dataRegionOverlays)
        
        for hgtFile in HGTManager.getLocalHGTFiles() {
            self.mapView.add(hgtFile.getBoundingBox().asMKPolygon())
        }
    }

    fileprivate func drawPin(_ observer: Observer) {
        let dropPin = MKPointAnnotation()
        dropPin.coordinate = observer.position
        dropPin.title = observer.description
        mapView.addAnnotation(dropPin)
    }
    
    
    fileprivate func redraw() {
        drawObservers()
        drawDataRegions()
    }
    
    fileprivate func addObserver(_ observer:Observer) {
        if(model.add(observer)) {
            drawPin(observer)
        }
    }

    func onLongPress(_ gestureRecognizer: UIGestureRecognizer) {
        if (gestureRecognizer.state == UIGestureRecognizerState.began) {
            if(HGTManager.getLocalHGTFileByName(HGTFile.coordinateToFilename(mapView.convert(gestureRecognizer.location(in: mapView), toCoordinateFrom: mapView), resolution: Srtm.SRTM3_RESOLUTION)) != nil) {
                let newObserver = Observer()
                newObserver.position = mapView.convert(gestureRecognizer.location(in: mapView), toCoordinateFrom: mapView)
                addObserver(newObserver)
            } else {
                self.view.makeToast("No elevation data here.\nDownload from the Data tab.", duration: 2.0, position: ToastPosition.center)
                return
            }
        }
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        var polygonView: MKPolygonRenderer? = nil
        if overlay is MKPolygon {
            polygonView = MKPolygonRenderer(overlay: overlay)
            polygonView!.lineWidth = 0.5
            polygonView!.fillColor = UIColor.yellow.withAlphaComponent(0.08)
            polygonView!.strokeColor = UIColor.red.withAlphaComponent(0.6)
        } else if overlay is GridOverlay {
            let imageToUse = (overlay as! GridOverlay).image
            let overlayView = GridOverlayView(overlay: overlay, overlayImage: imageToUse)

            return overlayView
        }

        return polygonView!
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        var view: MKPinAnnotationView? = nil
        let identifier = "pin"
        if (annotation is MKUserLocation) {
            //if annotation is not an MKPointAnnotation (eg. MKUserLocation),
            //return nil so map draws default view for it (eg. blue bubble)...
            return nil
        }
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view!.canShowCallout = true
            view!.calloutOffset = CGPoint(x: -5, y: 5)

            let image = UIImage(named: "Viewshed")
            let button = UIButton(type: UIButtonType.detailDisclosure)
            button.setImage(image, for: UIControlState())

            view!.leftCalloutAccessoryView = button as UIView
            view!.rightCalloutAccessoryView = UIButton(type: UIButtonType.detailDisclosure) as UIView
        }

        return view
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let selectedObserver = retrieveObserver((view.annotation?.coordinate)!) {
            if control == view.rightCalloutAccessoryView {
                performSegue(withIdentifier: "observerSettings", sender: selectedObserver)
            } else if control == view.leftCalloutAccessoryView {
                self.initiateFogViewshed(selectedObserver)
            }
        } else {
            print("Observer not found for \((view.annotation?.coordinate)!)")
        }
    }

    fileprivate func setupMapLog() {
        var multiplier: CGFloat = 1.0
        if(UserDefaults.standard.bool(forKey: "isLogShown")) {
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

        NSLayoutConstraint.deactivate([mapViewProportionalHeight])
        NSLayoutConstraint.activate([newMapViewProportionalHeight])

        mapViewProportionalHeight = newMapViewProportionalHeight
    }

    func retrieveObserver(_ coordinate: CLLocationCoordinate2D) -> Observer? {
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

    func initiateFogViewshed(_ observer: Observer) {
        _ = EZLoadingActivity.show("Calculating Viewshed", disableUI: false)
        
        self.ViewshedLog("Running viewshed")
        (FogMachine.fogMachineInstance.getTool() as! ViewshedTool).createWorkViewshedObserver = observer
        (FogMachine.fogMachineInstance.getTool() as! ViewshedTool).createWorkViewshedAlgorithmName = ViewshedAlgorithmName.FranklinRay
        FogMachine.fogMachineInstance.execute()
    }
    
    func display3dViewshed(_ elevationDataGrid: DataGrid) {
        viewshedSceneView = SCNView(frame: self.view.frame)
        viewshedSceneView.allowsCameraControl = true
        viewshedSceneView.autoenablesDefaultLighting = true
        viewshedSceneView.backgroundColor = UIColor.lightGray
        viewshedSceneView.antialiasingMode = SCNAntialiasingMode.multisampling4X
        
        let viewshedScene = SCNScene()
        viewshedSceneView.scene = viewshedScene
        
        let location:CGPoint = CGPoint.init(x: elevationDataGrid.boundingBoxAreaExtent.getCentroid().latitude, y: elevationDataGrid.boundingBoxAreaExtent.getCentroid().longitude)
        let observerGridLocation:(Int, Int) = HGTManager.latLonToIndex(elevationDataGrid.boundingBoxAreaExtent.getCentroid(), boundingBox: elevationDataGrid.boundingBoxAreaExtent, resolution: elevationDataGrid.resolution)
        var viewshedImage: UIImage? = nil
        if let image = viewshedResultImage[String(describing: location)] {
            viewshedImage = image
        }
        
        let elevationNode:ElevationScene = ElevationScene(elevation: elevationDataGrid.data, viewshedImage: viewshedImage)
        elevationNode.generateScene()
        elevationNode.drawVertices()
        elevationNode.addObserver(observerGridLocation, altitude: settingsObserver.elevationInMeters)
        elevationNode.addCamera()
        viewshedScene.rootNode.addChildNode(elevationNode)
        
        self.view.addSubview(viewshedSceneView)
    }

    // MARK: IBActions

    @IBAction func mapTypeChanged(_ sender: AnyObject) {
        let mapType = MapType(rawValue: mapTypeSelector.selectedSegmentIndex)
        switch (mapType!) {
        case .standard:
            mapView.mapType = MKMapType.standard
        case .hybrid:
            mapView.mapType = MKMapType.hybrid
        case .satellite:
            mapView.mapType = MKMapType.satellite
        }
    }

    @IBAction func focusToCurrentLocation(_ sender: AnyObject) {
        self.locationManager.startUpdatingLocation()
    }
    
    // MARK: Segue

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "observerSettings" {
            let viewController: ObserverSettingsViewController = segue.destination as! ObserverSettingsViewController
            viewController.originalObserver = sender as! Observer?
        }
    }

    @IBAction func applyOptions(_ segue: UIStoryboardSegue) {

    }

    @IBAction func removeViewshedFromSettings(_ segue: UIStoryboardSegue) {
        mapView.removeOverlays(mapView.overlays)
        redraw()
    }

    @IBAction func removePinFromSettings(_ segue: UIStoryboardSegue) {
        redraw()
    }

    @IBAction func deleteAllPins(_ segue: UIStoryboardSegue) {
        model.clearEntity()
        redraw()
    }

    @IBAction func runSelectedFogViewshed(_ segue: UIStoryboardSegue) {
        self.initiateFogViewshed(self.settingsObserver)
    }

    @IBAction func drawElevationData(_ segue: UIStoryboardSegue) {
        ElevationTool(elevationObserver: self.settingsObserver).drawElevationData()
    }
    
    @IBAction func draw3dElevationData(_ segue: UIStoryboardSegue) {
        ElevationTool(elevationObserver: self.settingsObserver).draw3dElevationData()
    }
    
    @IBAction func applyObserverSettings(_ segue:UIStoryboardSegue) {
        if segue.source.isKind(of: ObserverSettingsViewController.self) {
            mapView.removeAnnotations(mapView.annotations)
            drawObservers()
        }
    }

    // MARK: Logging

    func ViewshedLog(_ format: String, writeToDebugLog: Bool = false, clearLog: Bool = false) {
        if(writeToDebugLog) {
            NSLog(format)
        }
        DispatchQueue.main.async {
            if(clearLog) {
                self.logBox.text = ""
            }
            let dateFormater = DateFormatter()
            dateFormater.dateFormat = DateFormatter.dateFormat(fromTemplate: "HH:mm:ss.SSS", options: 0, locale:  Locale.current)
            let currentTimestamp: String = dateFormater.string(from: Date())
            DispatchQueue.main.async {
                self.logBox.text.append(currentTimestamp + " " + format + "\n")
                self.logBox.scrollRangeToVisible(NSMakeRange(self.logBox.text.characters.count - 1, 1))
            }
        }
    }

}
