//
//  MapViewController.swift
//  FogMachine
//
//  Created by Chris Wasko on 11/4/15.
//  Copyright © 2015 NGA. All rights reserved.
//

import UIKit
import MapKit
import Fog

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UITabBarControllerDelegate {

    
    // MARK: Class Variables
    
    
    var allObservers = [ObserverEntity]()
    var model = ObserverFacade()
    var settingsObserver = Observer() //Only use for segue from ObserverSettings
    var viewshedPalette: ViewshedPalette!
    var isLogShown: Bool!
    var metricsOutput:String!
    var startTime: CFAbsoluteTime!//UInt64!//CFAbsoluteTime!
    var elapsedTime: CFAbsoluteTime!
    var locationManager: CLLocationManager!
    var isInitialAuthorizationCheck = false
    var isDataRegionDrawn = false
    var hasFogViewshedStarted = false
    
    private let serialQueue = dispatch_queue_create("mil.nga.magic.fog.results", DISPATCH_QUEUE_SERIAL)

    
    // MARK: IBOutlets

    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapTypeSelector: UISegmentedControl!
    @IBOutlet weak var logBox: UITextView!
    @IBOutlet weak var mapViewProportionalHeight: NSLayoutConstraint!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBarController!.delegate = self
        mapView.delegate = self
        let gesture = UILongPressGestureRecognizer(target: self, action: "addAnnotationGesture:")
        gesture.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(gesture)
        
        metricsOutput = ""
        isLogShown = false
        logBox.text = "Connected to \(ConnectionManager.otherWorkers.count) peers.\n"
        logBox.editable = false
        
        allObservers = model.getObservers()
        displayObservations()
        displayDataRegions()
        viewshedPalette = ViewshedPalette()

        locationManagerSettings()
        if allObservers.count > 0 {
            //Center on the last observer
            self.centerMapOnLocation(allObservers[allObservers.count - 1].getObserver().getObserverLocation())
        }
        setupFogViewshedEvents()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - TabBarController Delegates
    
    
    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        //If the selected viewController is the main mapViewController
        if viewController == tabBarController.viewControllers?[1] {
            removeDataRegions()
            displayDataRegions()
        }
    }
    
    
    // MARK: Location Delegate Methods
    
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if (status == .AuthorizedWhenInUse || status == .AuthorizedAlways) {
            self.locationManager.startUpdatingLocation()
            self.isInitialAuthorizationCheck = true
            self.mapView.showsUserLocation = true
        }
    }
    
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if (self.isInitialAuthorizationCheck) {
            let location = locations.last
            let center = CLLocationCoordinate2D(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5))
            self.mapView.tintColor = UIColor.blueColor()
            self.mapView?.centerCoordinate = location!.coordinate
            self.mapView.setRegion(region, animated: true)
            self.locationManager.stopUpdatingLocation()
        }
    }
    
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Error: " + error.localizedDescription)
    }
    
    
    func centerMapOnLocation(location: CLLocationCoordinate2D) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location, Srtm3.DISPLAY_DIAMETER * 2, Srtm3.DISPLAY_DIAMETER * 2)
        mapView.setRegion(coordinateRegion, animated: true)
    }
   
    
    func locationManagerSettings() {
        if (self.locationManager == nil) {
            self.locationManager = CLLocationManager()
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.delegate = self
        }
        let status = CLLocationManager.authorizationStatus()
        if (status == .NotDetermined || status == .Denied || status == .Restricted)  {
            // present an alert indicating location authorization required
            // and offer to take the user to Settings for the app via
            self.locationManager.requestWhenInUseAuthorization()
            self.mapView.tintColor = UIColor.blueColor()
        }
        if let coordinate = mapView.userLocation.location?.coordinate {
            let center = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
            self.mapView.setRegion(region, animated: true)
        }
    }
    
    
    // MARK: - Display Manipulations
    
    
    func displayObservations() {
        for entity in allObservers {
            pinObserverLocation(entity.getObserver())
        }
    }
    
    
    func displayDataRegions() {
        if !isDataRegionDrawn {
            let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
            
            do {
                let directoryUrls = try  NSFileManager.defaultManager().contentsOfDirectoryAtURL(documentsUrl, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions())
                let hgtFiles = directoryUrls.filter{ $0.pathExtension == "hgt" }.map{ $0.lastPathComponent }
                for file in hgtFiles{
                    let name = file!.componentsSeparatedByString(".")[0]
                    let tempHgt = Hgt(filename: name)
                    self.mapView.addOverlay(tempHgt.getRectangularBoundry())
                }
            } catch let error as NSError {
                print("Error displaying HGT file: \(error.localizedDescription)")
            }
            isDataRegionDrawn = true
        }
    }
    
    
    func removeDataRegions() {
        var dataRegionOverlays = [MKOverlay]()
        for overlay in mapView.overlays {
            if overlay is MKPolygon {
                dataRegionOverlays.append(overlay)
            }
        }
        
        if dataRegionOverlays.count > 0 {
            mapView.removeOverlays(dataRegionOverlays)
            isDataRegionDrawn = false
        }
    }
    
    
    func pinObserverLocation(observer: Observer) {
        let dropPin = MKPointAnnotation()
        dropPin.coordinate = observer.getObserverLocation()
        dropPin.title = observer.name
        mapView.addAnnotation(dropPin)
    }
    
    
    func addAnnotationGesture(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == UIGestureRecognizerState.Began {
            let touchPoint = gestureRecognizer.locationInView(mapView)
            let newCoordinates = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            let tempHgt = Hgt(coordinate: newCoordinates)
            if tempHgt.hasHgtFileInDocuments() {
                let newObserver = Observer()
                newObserver.name = "Observer \(allObservers.count + 1)"
                newObserver.setNewCoordinates(newCoordinates)
                model.populateEntity(newObserver)
                //Repopulate allObservers with new Observer
                allObservers = model.getObservers()
                pinObserverLocation(newObserver)
            } else {
                var style = ToastStyle()
                style.messageColor = UIColor.redColor()
                style.backgroundColor = UIColor.whiteColor()
                style.messageFont = UIFont(name: "HelveticaNeue", size: 16)
                self.view.makeToast("Data unavailable for this location", duration: 1.5, position: .Center, style: style)
                return
            }
        }
    }

    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        var polygonView:MKPolygonRenderer? = nil
        if overlay is MKPolygon {
            polygonView = MKPolygonRenderer(overlay: overlay)
            polygonView!.lineWidth = 0.5
            // FIXME : if fill color is set, the viewsheds combine with the yellow tint and look like crap.  We should look at the compositing of the views/images to fix this.
            // polygonView!.fillColor = UIColor.yellowColor().colorWithAlphaComponent(0.08)
            polygonView!.strokeColor = UIColor.redColor().colorWithAlphaComponent(0.6)
        } else if overlay is Cell {
            polygonView = MKPolygonRenderer(overlay: overlay)
            polygonView!.lineWidth = 0.1
            let color:UIColor = (overlay as! Cell).color!
            polygonView!.strokeColor = color
            polygonView!.fillColor = color.colorWithAlphaComponent(0.3)
        } else if overlay is ViewshedOverlay {
            let imageToUse = (overlay as! ViewshedOverlay).image
            let overlayView = ViewshedOverlayView(overlay: overlay, overlayImage: imageToUse)
            
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
                self.initiateFogViewshed(selectedObserver.getObserver())
            }
        } else {
            print("Observer not found for \((view.annotation?.coordinate)!)")
        }
    }
    
    
    func changeMultiplier(constraint: NSLayoutConstraint, multiplier: CGFloat) -> NSLayoutConstraint {
        let newConstraint = NSLayoutConstraint(
            item: constraint.firstItem,
            attribute: constraint.firstAttribute,
            relatedBy: constraint.relation,
            toItem: constraint.secondItem,
            attribute: constraint.secondAttribute,
            multiplier: multiplier,
            constant: constraint.constant)
        
        newConstraint.priority = constraint.priority
        
        NSLayoutConstraint.deactivateConstraints([constraint])
        NSLayoutConstraint.activateConstraints([newConstraint])
        
        return newConstraint
    }
    
    
    func setMapLogDisplay() {
        guard let isLogShown = self.isLogShown else {
            mapViewProportionalHeight = changeMultiplier(mapViewProportionalHeight, multiplier: 1.0)
            return
        }
        
        if isLogShown {
            mapViewProportionalHeight = changeMultiplier(mapViewProportionalHeight, multiplier: 0.7)
        } else {
            mapViewProportionalHeight = changeMultiplier(mapViewProportionalHeight, multiplier: 1.0)
        }
    }
    
    
    func retrieveObserver(coordinate: CLLocationCoordinate2D) -> ObserverEntity? {
        var foundObserver: ObserverEntity? = nil
        
        for observer in allObservers
        {
            if coordinate.latitude == observer.latitude && coordinate.longitude == observer.longitude {
                foundObserver = observer
                break
            }
        }
        return foundObserver
    }
    
    
    func removeAllFromMap() {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        isDataRegionDrawn = false
    }
    
    
    func redrawMap() {
        allObservers = model.getObservers()
        removeAllFromMap()
        displayObservations()
        displayDataRegions()
    }
    
    
    // MARK: - Fog Viewshed
    
    
    func initiateFogViewshed(observer: Observer) {
        
        if !self.hasFogViewshedStarted {
            if (self.viewshedPalette.isViewshedPossible(observer)) {
                dispatch_async(dispatch_get_main_queue()) {
                    self.logBox.text = ""
                }
                self.startTimer()
                ActivityIndicator.show("Calculating Viewshed")
                dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
                    self.hasFogViewshedStarted = true
                    self.startFogViewshed(observer)
                }
                //self.verifyBoundBox(observer)
            } else {
                let message = "Fog Viewshed requires the surrounding HGT files.\n\nDownload the missing Hgt files from the Data Tab."
                let alertController = UIAlertController(title: "Fog Viewshed", message: message, preferredStyle: .Alert)
                
                let cancelAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel) { (action) in
                    // Do noting for cancel
                }
                alertController.addAction(cancelAction)
                self.presentViewController(alertController, animated: true) {
                    // Do nothing
                }
            }
        } else {
            let message = "Fog Viewshed is being calculated.\n\nPlease wait for the viewshed to finish before starting another viewshed."
            let alertController = UIAlertController(title: "Fog Viewshed", message: message, preferredStyle: .Alert)
            
            let cancelAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel) { (action) in
                // Do nothing for cancel
            }
            alertController.addAction(cancelAction)
            self.presentViewController(alertController, animated: true) {
                // Do nothing
            }
        }
    }
    
    
    func startFogViewshed(observer: Observer) {
        printOut("Beginning viewshed on \(Worker.getMe().displayName)")
        
        let selfQuadrant = 1
        var count = 1 //Start at one since initiator is 0-indexed
        
        ConnectionManager.sendEventToAll(Event.StartViewshed.rawValue,
            workForPeer: { workerCount in
                let workDivision = self.getQuadrant(workerCount)
                let currentQuadrant = workDivision[count]
                let theWork = ViewshedWork(numberOfQuadrants: workerCount, whichQuadrant: currentQuadrant, observer: observer)
                count++
                
                return theWork
            },
            workForSelf: { workerCount in
                self.printOut("\tBeginning viewshed locally for 1 from \(workerCount)")
                self.performFogViewshed(observer, numberOfQuadrants: workerCount, whichQuadrant: selfQuadrant)
                
                if (workerCount < 2) {
                    //if no peers
                    let viewshedOverlay = self.viewshedPalette.getViewshedOverlay()
                    dispatch_async(dispatch_get_main_queue()) {
                        self.mapView.addOverlay(viewshedOverlay)
                    }
                    self.hasFogViewshedStarted = false
                    ActivityIndicator.hide(success: true, animated: true)
                    self.stopTimer()
                }
                self.printOut("\tFound results locally out of \(workerCount).")
            },
            log: { peerName in
                self.printOut("Sent \(Event.StartViewshed.rawValue) to \(peerName)")
            }
        )
    }
    
    
    func performFogViewshed(observer: Observer, numberOfQuadrants: Int, whichQuadrant: Int) {
        
        printOut("Starting Fog Viewshed Processing on Observer: \(observer.name)")
        self.viewshedPalette.setupNewPalette(observer)
        
        if (observer.algorithm == ViewshedAlgorithm.FranklinRay) {
            let obsViewshed = ViewshedFog(elevation: self.viewshedPalette.getHgtElevation(), observer: observer, numberOfQuadrants: numberOfQuadrants, whichQuadrant: whichQuadrant)
            self.viewshedPalette.viewshedResults = obsViewshed.viewshedParallel()
        } else if (observer.algorithm == ViewshedAlgorithm.VanKreveld) {
            let kreveld: KreveldViewshed = KreveldViewshed()
            let demObj: DemData = DemData(demMatrix: self.viewshedPalette.getHgtElevation())
            let observerPoints: ElevationPoint = ElevationPoint (xCoord: observer.xCoord, yCoord: observer.yCoord, h: Double(observer.elevation))
            self.viewshedPalette.viewshedResults = kreveld.parallelKreveld(demObj, observPt: observerPoints, radius: observer.getViewshedSrtm3Radius(), numOfPeers: numberOfQuadrants, quadrant2Calc: whichQuadrant)
            
        }
        
        printOut("\tFinished Viewshed Processing on \(observer.name).")
        
        self.pinObserverLocation(observer)
    }
    
    
    func setupFogViewshedEvents() {
        
        ConnectionManager.onEvent(Event.StartViewshed.rawValue){ fromPeerId, object in
            self.printOut("Recieved request to initiate a viewshed from \(fromPeerId.displayName)")
            let dict = object as! [String: NSData]
            let work = ViewshedWork(mpcSerialized: dict[Event.StartViewshed.rawValue]!)
            
            self.printOut("\tBeginning viewshed for \(work.whichQuadrant) from \(work.numberOfQuadrants)")
            self.performFogViewshed(work.getObserver(), numberOfQuadrants: work.numberOfQuadrants, whichQuadrant: work.whichQuadrant)
            
            //Uncomment if passing [[Int]]
            //let result = ViewshedResult(viewshedResult: self.viewshedResults)
            
            self.printOut("\tDisplay result locally on \(Worker.getMe().displayName)")
            let viewshedOverlay = self.viewshedPalette.getViewshedOverlay()
            
            dispatch_async(dispatch_get_main_queue()) {
                self.mapView.addOverlay(viewshedOverlay)
            }
            
            
            //Use if passing UIImage
            let result = ViewshedResult(viewshedResult: self.viewshedPalette.viewshedImage)//self.viewshedResults)
            
            
            self.printOut("\tSending \(Event.SendViewshedResult.rawValue) from \(Worker.getMe().displayName) to \(fromPeerId.displayName)")
            
            ConnectionManager.sendEventTo(Event.SendViewshedResult.rawValue, object: [Event.SendViewshedResult.rawValue: result], sendTo: fromPeerId.displayName)
        }
        
        ConnectionManager.onEvent(Event.SendViewshedResult.rawValue) { fromPeerId, object in
            
            var dict = object as! [NSString: NSData]
            let result = ViewshedResult(mpcSerialized: dict[Event.SendViewshedResult.rawValue]!)
            
            ConnectionManager.processResult(Event.SendViewshedResult.rawValue, responseEvent: Event.StartViewshed.rawValue, sender: fromPeerId.displayName, object: [Event.SendViewshedResult.rawValue: result],
                responseMethod: {
                    
                    // dispatch_barrier_async(dispatch_queue_create("mil.nga.magic.fog.results", DISPATCH_QUEUE_CONCURRENT)) {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.printOut("\tResult recieved from \(fromPeerId.displayName).")
                        //   }
                        //self.viewshedResults = self.mergeViewshedResults(self.viewshedResults, viewshedTwo: result.viewshedResult)
                        
                        let viewshedOverlay = self.viewshedPalette.addOverlay(result.viewshedResult)
                        self.mapView.addOverlay(viewshedOverlay)
                    }
                },
                completeMethod: {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.printOut("\tAll received")
                        let viewshedOverlay = self.viewshedPalette.getViewshedOverlay()
                        self.mapView.addOverlay(viewshedOverlay)
                        self.printOut("Viewshed complete.")
                        self.hasFogViewshedStarted = false
                        ActivityIndicator.hide(success: true, animated: true)
                        self.stopTimer()
                    }
            })
            //}
        }
        
    }
    
    
    private func getQuadrant(numberOfWorkers: Int) -> [Int] {
        var quadrants:[Int] = []
        
        for var count = 0; count < numberOfWorkers; count++ {
            quadrants.append(count + 1)
        }
        
        return quadrants
    }
    
    
    // MARK: - IBActions
    
    
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
        locationManagerSettings()
    }
    
    
    // MARK: Segue
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "observerSettings" {
            let navController = segue.destinationViewController as! UINavigationController
            let viewController: ObserverSettingsViewController = navController.topViewController as! ObserverSettingsViewController
            viewController.originalObserver = sender as! ObserverEntity?
        } else if segue.identifier == "settings" {
            let navController = segue.destinationViewController as! UINavigationController
            let viewController: SettingsViewController = navController.topViewController as! SettingsViewController
            viewController.isLogShown = self.isLogShown
        }
    }
    
    
    @IBAction func unwindFromModal(segue: UIStoryboardSegue) {
        setMapLogDisplay()
        removeDataRegions()
        isDataRegionDrawn = false
        displayDataRegions()
    }
    
    
    @IBAction func applyOptions(segue: UIStoryboardSegue) {
        
    }
    
    
    @IBAction func removeViewshedFromSettings(segue: UIStoryboardSegue) {
        setMapLogDisplay()
        redrawMap()
        self.logBox.text = "Connected to \(ConnectionManager.otherWorkers.count) peers.\n"
    }
    
    
    @IBAction func removePinFromSettings(segue: UIStoryboardSegue) {
        redrawMap()
    }
    
    
    @IBAction func deleteAllPins(segue: UIStoryboardSegue) {
        setMapLogDisplay()
        model.clearEntity()
        redrawMap()
    }
    
    
    @IBAction func runSelectedFogViewshed(segue: UIStoryboardSegue) {
        redrawMap()
        self.initiateFogViewshed(self.settingsObserver)
    }
    
    
    @IBAction func applyObserverSettings(segue:UIStoryboardSegue) {
        if segue.sourceViewController.isKindOfClass(ObserverSettingsViewController) {
            allObservers = model.getObservers()
            mapView.removeAnnotations(mapView.annotations)
            displayObservations()
        }
    }
    
    
    // MARK: Testing
    
    
    func singleRandomObserver() -> Observer {
        let name = String(arc4random_uniform(10000) + 1)
        let xCoord = Int(arc4random_uniform(700) + 200)
        let yCoord = Int(arc4random_uniform(700) + 200)
        let defaultHgtFilename = "N39W075"
        let defaultHgt = Hgt(filename: defaultHgtFilename)
        return Observer(name: name, xCoord: xCoord, yCoord: yCoord, elevation: 20, radius: 300, coordinate: defaultHgt.getCoordinate())
    }
    
    
    func singleViewshed(algorithm: ViewshedAlgorithm) {
        self.performSerialViewshed(singleRandomObserver(), algorithm: algorithm)
    }
    
    
    func verifyBoundBox(observer: Observer) {
        let boundingBox = BoundingBox()
        let box = boundingBox.getBoundingBox(observer)
        
        var points = [
            box.lowerLeft,
            box.upperLeft,
            box.upperRight,
            box.lowerRight
        ]
        let polygonOverlay:MKPolygon = MKPolygon(coordinates: &points, count: points.count)
        self.mapView.addOverlay(polygonOverlay)
    }
    
    
    // MARK: Timer
    
    
    func startTimer() {
        startTime = CFAbsoluteTimeGetCurrent()
        //startParallelTimer = mach_absolute_time()
    }
    
    
    func stopTimer(toPrint: Bool=false, observer: String="") -> CFAbsoluteTime {
        elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
        self.printOut("Stop Time: " + String(format: "%.6f", elapsedTime))
        //let elapsedTime = mach_absolute_time() - startParallelTimer
        if toPrint {
            self.printOut("Observer \(observer):\t\(elapsedTime)")
        }
        return elapsedTime
    }
    
    
    func clearTimer() {
        startTime = 0
        elapsedTime = 0
    }
    
    
    // MARK: Logging/Printing
    
    
    func printOut(output: String) {
        dispatch_async(dispatch_get_main_queue()) {
            let range = NSMakeRange(0, (output as NSString).length)
            if let regex = try? NSRegularExpression(pattern: "😺[0-9]*", options: .CaseInsensitive) {
                let printableOutput = regex.stringByReplacingMatchesInString(output, options: .WithTransparentBounds, range: range, withTemplate: "")
                //Can easily change this to print out to a file without modifying the rest of the code.
                print(printableOutput)
                //metricsOutput = metricsOutput + "\n" + output
                self.logBox.text = self.logBox.text + "\n" + printableOutput
            }
        }
    }
    
    
    // MARK: Metrics
    
    
    func initiateMetricsGathering(algorithm: ViewshedAlgorithm) {
        var metricGroup = dispatch_group_create()
        
        dispatch_group_enter(metricGroup)
        self.gatherMetrics(false, metricGroup: metricGroup, algorithm: algorithm)
        
        dispatch_group_notify(metricGroup, dispatch_get_main_queue()) {
            metricGroup = dispatch_group_create()
            
            dispatch_group_enter(metricGroup)
            self.gatherMetrics(true, metricGroup: metricGroup, algorithm: algorithm)
            
            dispatch_group_notify(metricGroup, dispatch_get_main_queue()) {
                print("All Done!")
            }
        }
    }
    
    
    func gatherMetrics(randomData: Bool, metricGroup: dispatch_group_t, algorithm: ViewshedAlgorithm) {
        metricsOutput = ""
        
        self.printOut("Metrics Report.")
        var viewshedGroup = dispatch_group_create()
        self.runComparison(2, viewshedGroup: viewshedGroup, randomData: randomData, algorithm: algorithm)
        
        dispatch_group_notify(viewshedGroup, dispatch_get_main_queue()) {
            viewshedGroup = dispatch_group_create()
            self.runComparison(4, viewshedGroup: viewshedGroup, randomData: randomData, algorithm: algorithm)
            
            dispatch_group_notify(viewshedGroup, dispatch_get_main_queue()) {
                viewshedGroup = dispatch_group_create()
                self.runComparison(8, viewshedGroup: viewshedGroup, randomData: randomData, algorithm: algorithm)
                
                dispatch_group_notify(viewshedGroup, dispatch_get_main_queue()) {
                    viewshedGroup = dispatch_group_create()
                    self.runComparison(16, viewshedGroup: viewshedGroup, randomData: randomData, algorithm: algorithm)
                    
                    dispatch_group_notify(viewshedGroup, dispatch_get_main_queue()) {
                        print("\nmetricsOutput\n\n\n\(self.metricsOutput)")
                        dispatch_group_leave(metricGroup)
                    }
                }
            }
        }
        
    }
    
    
    func runComparison(numObservers: Int, viewshedGroup: dispatch_group_t, randomData: Bool, algorithm: ViewshedAlgorithm){
        
        var observers: [Observer] = []
        var xCoord:Int
        var yCoord:Int
        var elevation:Int
        var radius:Int
        let defaultHgtFilename = "N39W075"
        let defaultHgt = Hgt(filename: defaultHgtFilename)
        
        self.printOut("Metrics Started for \(numObservers) observer(s).")
        if randomData {
            self.printOut("Using random data.")
        } else {
            self.printOut("Using pattern data from top left to bottom right.")
        }
        
        for count in 1...numObservers {
            let name = "Observer " + String(count)
            
            if randomData {
                //Random Data
                xCoord = Int(arc4random_uniform(700) + 200)
                yCoord = Int(arc4random_uniform(700) + 200)
                elevation = Int(arc4random_uniform(100) + 1)
                radius = Int(arc4random_uniform(600) + 1)
            } else {
                //Pattern Data - Right Diagonal
                xCoord = count * 74
                yCoord = count * 74
                elevation = count + 5
                radius = count + 100 //If the radius grows substantially larger then the parallel threads will finish sequentially
            }
            
            let observer = Observer(name: name, xCoord: xCoord, yCoord: yCoord, elevation: elevation, radius: radius, coordinate: defaultHgt.getCoordinate())
            self.printOut("\tObserver \(name): x: \(xCoord)\ty: \(yCoord)\theight: \(elevation)\tradius: \(radius)")
            observers.append(observer)
        }
        
        //Starting serial before the parallel so the parallel will not be running when the serial runs
        self.printOut("\nStarting Serial Viewshed")
        
        self.startTimer()
        for obs in observers {
            self.performSerialViewshed(obs, algorithm: algorithm)
        }
        self.stopTimer()
        self.removeAllFromMap()
        
        self.printOut("Serial Viewshed Total Time: \(self.elapsedTime)")
        self.printOut("\nStarting Parallel Viewshed")
        
        self.startTimer()
        for obsP in observers {
            self.performParallelViewshed(obsP, algorithm: algorithm, viewshedGroup: viewshedGroup)
        }
        
        dispatch_group_notify(viewshedGroup, dispatch_get_main_queue()) {
            self.stopTimer()
            self.printOut("Parallel Viewshed Total Time: \(self.elapsedTime)")
            print("Parallel Viewshed Total Time: \(self.elapsedTime)")
            self.clearTimer()
            self.printOut("Metrics Finished for \(numObservers) Observer(s).\n")
        }
        
    }
    
    
    func performParallelViewshed(observer: Observer, algorithm: ViewshedAlgorithm, viewshedGroup: dispatch_group_t) {
        
        dispatch_group_enter(viewshedGroup)
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
            
            self.printOut("Starting Parallel Viewshed Processing on \(observer.name).")
            
            if (algorithm == ViewshedAlgorithm.FranklinRay) {
                let obsViewshed = Viewshed(elevation: self.viewshedPalette.getHgtElevation(), observer: observer)
                self.viewshedPalette.viewshedResults = obsViewshed.viewshed()
            } else if (algorithm == ViewshedAlgorithm.VanKreveld) {
                // running Van Kreveld viewshed.
                let kreveld: KreveldViewshed = KreveldViewshed()
                let demObj: DemData = DemData(demMatrix: self.viewshedPalette.getHgtElevation())
                let observerPoints: ElevationPoint = ElevationPoint (xCoord:observer.xCoord, yCoord: observer.yCoord)
                self.viewshedPalette.viewshedResults = kreveld.parallelKreveld(demObj, observPt: observerPoints, radius: observer.getViewshedSrtm3Radius(), numOfPeers: 1, quadrant2Calc: 0)
                //obsResults = kreveld.calculateViewshed(demObj, observPt: observerPoints, radius: observer.radius, numQuadrants: 0, quadrant2Calc: 0)
            }
            dispatch_async(dispatch_get_main_queue()) {
                
                self.printOut("\tFinished Viewshed Processing on \(observer.name).")
                
                self.pinObserverLocation(observer)
                let viewshedOverlay = self.viewshedPalette.getViewshedOverlay()
                self.mapView.addOverlay(viewshedOverlay)
                
                dispatch_group_leave(viewshedGroup)
            }
        }
    }
    
    
    func performSerialViewshed(observer: Observer, algorithm: ViewshedAlgorithm) {
        
        self.printOut("Starting Serial Viewshed Processing on \(observer.name).")
        
        if (algorithm == ViewshedAlgorithm.FranklinRay) {
            let obsViewshed = Viewshed(elevation: self.viewshedPalette.getHgtElevation(), observer: observer)
            self.viewshedPalette.viewshedResults = obsViewshed.viewshed()
        } else if (algorithm == ViewshedAlgorithm.VanKreveld) {
            let kreveld: KreveldViewshed = KreveldViewshed()
            let demObj: DemData = DemData(demMatrix: self.viewshedPalette.getHgtElevation())
            // observer.radius = 200 // default radius 100
            // set the added observer height
            let observerPoints: ElevationPoint = ElevationPoint (xCoord:observer.xCoord, yCoord: observer.yCoord, h: Double(observer.elevation))
            self.viewshedPalette.viewshedResults = kreveld.parallelKreveld(demObj, observPt: observerPoints, radius: observer.getViewshedSrtm3Radius(), numOfPeers: 1, quadrant2Calc: 1)
            //obsResults = kreveld.calculateViewshed(demObj, observPt: observerPoints, radius: observer.radius, numQuadrants: 0, quadrant2Calc: 0)
        }
        
        self.printOut("\tFinished Viewshed Processing on \(observer.name).")
        
        self.pinObserverLocation(observer)
        
        let viewshedOverlay = self.viewshedPalette.getViewshedOverlay()
        dispatch_async(dispatch_get_main_queue()) {
            self.mapView.addOverlay(viewshedOverlay)
        }
    }
    
    
    func startParallel(algorithm: ViewshedAlgorithm) {
        
        let defaultHgtFilename = "N39W075"
        let defaultHgt = Hgt(filename: defaultHgtFilename)
        let viewshedGroup = dispatch_group_create()
        self.startTimer()
        //  dispatch_apply(8, dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) { index in
        // let count = Int(index + 1)
        for count in 1...8 {
            
            let observer = Observer(name: String(count), xCoord: count * 100, yCoord: count * 100, elevation: 20, radius: 600, coordinate: defaultHgt.getCoordinate())
            
            self.performParallelViewshed(observer, algorithm: algorithm, viewshedGroup: viewshedGroup)
        }
        
        dispatch_group_notify(viewshedGroup, dispatch_get_main_queue()) {
            self.stopTimer()
        }
    }
    
    
    func startSerial(algorithm: ViewshedAlgorithm) {
        
        let defaultHgtFilename = "N39W075"
        let defaultHgt = Hgt(filename: defaultHgtFilename)
        self.startTimer()
        
        for count in 1...8 {
            //let observer = Observer(name: String(count), x: count * 100, y: count * 100, height: 20, radius: options.radius, coordinate: self.hgtCoordinate)
            let observer = Observer(name: String(count), xCoord: 600, yCoord: 600, elevation: 20, radius: 600, coordinate: defaultHgt.getCoordinate())
            //let observer = Observer(name: String(count), x: 8 * 100, y: 8 * 100, height: 20, radius: options.radius, coordinate:self.hgtCoordinate)
            self.performSerialViewshed(observer, algorithm: algorithm)
        }
        
        self.stopTimer()
    }
    
}
