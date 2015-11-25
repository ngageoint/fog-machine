//
//  MapViewController.swift
//  FogMachineSearch
//
//  Created by Chris Wasko on 11/4/15.
//  Copyright © 2015 NGA. All rights reserved.
//

import UIKit
import MapKit


class MapViewController: UIViewController, MKMapViewDelegate {

    
    // MARK: IBOutlets
    
    
    @IBOutlet weak var mapView: MKMapView!

    @IBOutlet weak var peerStatusLabel: UILabel!
    @IBOutlet weak var serialLabel: UILabel!
    @IBOutlet weak var parallelLabel: UILabel!
    @IBOutlet weak var mapTypeSelector: UISegmentedControl!
    
    
    // MARK: Class Variables
    
    
    var metricsOutput:String!
    var startParallelTime: CFAbsoluteTime!//UInt64!//CFAbsoluteTime!
    var elapsedParallelTime: CFAbsoluteTime!
    var startSerialTime: CFAbsoluteTime!
    var elapsedSerialTime: CFAbsoluteTime!
    var hgt: Hgt!
    var hgtCoordinate:CLLocationCoordinate2D!
    var hgtElevation:[[Int]]!
    
    var responsesRecieved = Dictionary<String, Bool>()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        peerStatusLabel.text = "Connected to \(ConnectionManager.otherWorkers.count) peers"
        mapView.delegate = self

        let hgtFilename = "N40W110"//"N39W075"//"N38W077"
        metricsOutput = ""

        hgt = Hgt(filename: hgtFilename)
        hgtCoordinate = hgt.getCoordinate()
        hgtElevation = hgt.getElevation()
        
        self.centerMapOnLocation(self.hgt.getCenterLocation())
        
        setupFogEvents()
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: Viewshed Serial/Parallel
    
    
    func singleTestObserver() -> Observer {
        let name = "Tester"
        let x = 900
        let y = 900
        return Observer(name: name, x: x, y: y, height: 20, radius: 300, coordinate: self.hgtCoordinate)
        
    }
    
    
    func singleRandomObserver() -> Observer {
        let name = String(arc4random_uniform(10000) + 1)
        let x = Int(arc4random_uniform(700) + 200)
        let y = Int(arc4random_uniform(700) + 200)
        return Observer(name: name, x: x, y: y, height: 20, radius: 300, coordinate: self.hgtCoordinate)
        
    }
    
    
    func singleViewshed() {
        self.performSerialViewshed(singleRandomObserver())
    }
    
    
    func performParallelViewshed(observer: Observer, viewshedGroup: dispatch_group_t) {
        
        dispatch_group_enter(viewshedGroup)
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
            
            print("Starting Parallel Viewshed Processing on \(observer.name).")
            
            let obsViewshed = Viewshed(elevation: self.hgtElevation, observer: observer)
            let obsResults:[[Int]] = obsViewshed.viewshed()
            
            dispatch_async(dispatch_get_main_queue()) {
                
                print("\tFinished Viewshed Processing on \(observer.name).")
                
                let image = self.generateViewshedImage(obsResults, hgtLocation: self.hgt.getCoordinate())
                self.pinObserverLocation(observer)
                self.addOverlay(image, imageLocation: self.hgtCoordinate)
                
                dispatch_group_leave(viewshedGroup)
           }
        }
    }
    
    
    func performSerialViewshed(observer: Observer) {
        
        print("Starting Serial Viewshed Processing on \(observer.name).")
        //observer.x = 600
        //observer.y = 600
        //observer.radius = 200
        
//        let obsViewshed = Viewshed(elevation: self.hgtElevation, observer: observer)
//        let obsResults:[[Int]] = obsViewshed.viewshed()

        // testing Kreveld viewshed..
        let kreveld: KreveldViewshedImpl = KreveldViewshedImpl()
        let demObj: DEMData = DEMData(demMatrix: self.hgtElevation)
        let observerPoints: ElevationPoint = ElevationPoint (x:observer.x, y: observer.y)
        let obsResults:[[Int]] = kreveld.calculateViewshed(demObj, observPt: observerPoints, radius: observer.radius)

        
        print("\tFinished Viewshed Processing on \(observer.name).")
        
        let image = self.generateViewshedImage(obsResults, hgtLocation: self.hgt.getCoordinate())
        self.pinObserverLocation(observer)
        self.addOverlay(image, imageLocation: self.hgtCoordinate)
    }
    
    
    // MARK: Display Manipulations
    
    
    func addOverlay(image: UIImage, imageLocation: CLLocationCoordinate2D) {

        var overlayTopLeftCoordinate: CLLocationCoordinate2D  = CLLocationCoordinate2D(
            latitude: imageLocation.latitude + 1.0,
            longitude: imageLocation.longitude)
        var overlayTopRightCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(
            latitude: imageLocation.latitude + 1.0,
            longitude: imageLocation.longitude + 1.0)
        var overlayBottomLeftCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(
            latitude: imageLocation.latitude,
            longitude: imageLocation.longitude)

        var overlayBottomRightCoordinate: CLLocationCoordinate2D {
            get {
                return CLLocationCoordinate2DMake(overlayBottomLeftCoordinate.latitude,
                    overlayTopRightCoordinate.longitude)
            }
        }
        
        var overlayBoundingMapRect: MKMapRect {
            get {
                let topLeft = MKMapPointForCoordinate(overlayTopLeftCoordinate)
                let topRight = MKMapPointForCoordinate(overlayTopRightCoordinate)
                let bottomLeft = MKMapPointForCoordinate(overlayBottomLeftCoordinate)
                
                return MKMapRectMake(topLeft.x,
                    topLeft.y,
                    fabs(topLeft.x-topRight.x),
                    fabs(topLeft.y - bottomLeft.y))
            }
        }
        
        let imageMapRect = overlayBoundingMapRect
        let overlay = ViewshedOverlay(midCoordinate: imageLocation, overlayBoundingMapRect: imageMapRect, viewshedImage: image)
        
        dispatch_async(dispatch_get_main_queue()) {
            self.mapView.addOverlay(overlay)
        }
    }
    
    
    func generateViewshedImage(viewshed: [[Int]], hgtLocation: CLLocationCoordinate2D) -> UIImage {

        let width = viewshed[0].count
        let height = viewshed.count
        var data: [Pixel] = []
        
        // CoreGraphics expects pixel data as rows, not columns.
        for(var y = 0; y < width; y++) {
            for(var x = 0; x < height; x++) {
                
                let cell = viewshed[y][x]
                if(cell == 0) {
                    data.append(Pixel(alpha: 15, red: 0, green: 0, blue: 0))
                } else if (cell == -1){
                    data.append(Pixel(alpha: 75, red: 126, green: 0, blue: 126))
                } else {
                    data.append(Pixel(alpha: 50, red: 0, green: 255, blue: 0))
                }
            }
        }
        
        let image = imageFromArgb32Bitmap(data, width: width, height: height)

        return image
        
    }
    
    
    func imageFromArgb32Bitmap(pixels:[Pixel], width: Int, height: Int)-> UIImage {
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo:CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedFirst.rawValue)
        let bitsPerComponent:Int = 8
        let bitsPerPixel:Int = 32
        let bytesPerRow = width * Int(sizeof(Pixel))
        
        // assert(pixels.count == Int(width * height))
        
        var data = pixels // Copy to mutable []
        let length = data.count * sizeof(Pixel)
        let providerRef = CGDataProviderCreateWithCFData(NSData(bytes: &data, length: length))
        
        let cgImage = CGImageCreate(
            width,
            height,
            bitsPerComponent,
            bitsPerPixel,
            bytesPerRow,
            rgbColorSpace,
            bitmapInfo,
            providerRef,
            nil,
            true,
            CGColorRenderingIntent.RenderingIntentDefault
        )
        return UIImage(CGImage: cgImage!)
    }
    
 
    func centerMapOnLocation(location: CLLocationCoordinate2D) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location, Srtm3.DISPLAY_DIAMETER, Srtm3.DISPLAY_DIAMETER)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    
    func pinObserverLocation(observer: Observer) {
        let dropPin = MKPointAnnotation()
        dropPin.coordinate = observer.getObserverLocation()
        dropPin.title = observer.name
        mapView.addAnnotation(dropPin)
    }
    
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        var polygonView:MKPolygonRenderer? = nil
//        if overlay is MKPolygon {
//            polygonView = MKPolygonRenderer(overlay: overlay)
//            polygonView!.lineWidth = 0.1
//            polygonView!.strokeColor = UIColor.grayColor()
//            polygonView!.fillColor = UIColor.grayColor().colorWithAlphaComponent(0.3)
//        } else
        if overlay is Cell {
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
        if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? MKPinAnnotationView {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view!.canShowCallout = true
            view!.calloutOffset = CGPoint(x: -5, y: 5)
            view!.rightCalloutAccessoryView = UIButton(type: UIButtonType.DetailDisclosure) as UIView
            view?.pinColor = MKPinAnnotationColor.Purple
        }
        
        return view
    }
    
    
    func removeAllFromMap() {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
    }
    
    
    // MARK: Timer
    
    
    func startParallelTimer() {
        startParallelTime = CFAbsoluteTimeGetCurrent()
        //startParallelTimer = mach_absolute_time()
    }
    
    
    func stopParallelTimer(toPrint: Bool=false, observer: String="") -> CFAbsoluteTime {
        elapsedParallelTime = CFAbsoluteTimeGetCurrent() - startParallelTime
        parallelLabel.text = String(format: "%.6f", elapsedParallelTime)
        //let elapsedTime = mach_absolute_time() - startParallelTimer
        //parallelLabel.text = String(elapsedTime)
        if toPrint {
            log("Observer \(observer):\t\(elapsedParallelTime)")
        }
        return elapsedParallelTime
    }

    
    func startSerialTimer() {
        startSerialTime = CFAbsoluteTimeGetCurrent()
    }
    
    
    func stopSerialTimer(toPrint: Bool=false, observer: String="") -> CFAbsoluteTime {
        elapsedSerialTime = CFAbsoluteTimeGetCurrent() - startSerialTime
        serialLabel.text = String(format: "%.6f", elapsedSerialTime)
        if toPrint {
            log("Observer \(observer):\t\(elapsedSerialTime)")
        }
        return elapsedSerialTime
    }

    
    func clearTimer() {
        parallelLabel.text = "0"
        serialLabel.text = "0"
        startParallelTime = 0
        startSerialTime = 0
        elapsedParallelTime = 0
        elapsedSerialTime = 0
    }
    
    
    // MARK: Logging/Printing
    
    
    func log(logMessage: String, functionName: String = __FUNCTION__) {
        printOut("\(functionName): \(logMessage)")
    }
    

    func printOut(output: String) {
        //Can easily change this to print out to a file without modifying the rest of the code.
        //print(output)
        metricsOutput = metricsOutput + "\n" + output
    }
    
    
    // MARK: Metrics
    
    
    func initiateMetricsGathering() {
        var metricGroup = dispatch_group_create()
        
        dispatch_group_enter(metricGroup)
        self.gatherMetrics(false, metricGroup: metricGroup)
        
        dispatch_group_notify(metricGroup, dispatch_get_main_queue()) {
            metricGroup = dispatch_group_create()
            
            dispatch_group_enter(metricGroup)
            self.gatherMetrics(true, metricGroup: metricGroup)
            
            dispatch_group_notify(metricGroup, dispatch_get_main_queue()) {
                print("All Done!")
            }
        }
    }
    
    
    func gatherMetrics(randomData: Bool, metricGroup: dispatch_group_t) {
        metricsOutput = ""
        
        self.printOut("Metrics Report.")
        var viewshedGroup = dispatch_group_create()
        self.runComparison(2, viewshedGroup: viewshedGroup, randomData: randomData)
        
        dispatch_group_notify(viewshedGroup, dispatch_get_main_queue()) {
            viewshedGroup = dispatch_group_create()
            self.runComparison(4, viewshedGroup: viewshedGroup, randomData: randomData)
            
            dispatch_group_notify(viewshedGroup, dispatch_get_main_queue()) {
                viewshedGroup = dispatch_group_create()
                self.runComparison(8, viewshedGroup: viewshedGroup, randomData: randomData)
                
                dispatch_group_notify(viewshedGroup, dispatch_get_main_queue()) {
                    viewshedGroup = dispatch_group_create()
                    self.runComparison(16, viewshedGroup: viewshedGroup, randomData: randomData)
                    
                    dispatch_group_notify(viewshedGroup, dispatch_get_main_queue()) {
                        print("\nmetricsOutput\n\n\n\(self.metricsOutput)")
                        dispatch_group_leave(metricGroup)
                    }
                }
            }
        }
        
    }
    
    
    func runComparison(numObservers: Int, viewshedGroup: dispatch_group_t, randomData: Bool){
        
        var observers: [Observer] = []
        var x:Int
        var y:Int
        var height:Int
        var radius:Int
        
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
                x = Int(arc4random_uniform(700) + 200)
                y = Int(arc4random_uniform(700) + 200)
                height = Int(arc4random_uniform(100) + 1)
                radius = Int(arc4random_uniform(600) + 1)
            } else {
                //Pattern Data - Right Diagonal
                x = count * 74
                y = count * 74
                height = count + 5
                radius = count + 100 //If the radius grows substantially larger then the parallel threads will finish sequentially
            }
            
            let observer = Observer(name: name, x: x, y: y, height: height, radius: radius, coordinate: self.hgtCoordinate)
            self.printOut("\tObserver \(name): x: \(x)\ty: \(y)\theight: \(height)\tradius: \(radius)")
            observers.append(observer)
        }
        
        //Starting serial before the parallel so the parallel will not be running when the serial runs
        self.printOut("\nStarting Serial Viewshed")
        
        self.startSerialTimer()
        for obs in observers {
            self.performSerialViewshed(obs)
        }
        self.stopSerialTimer()
        self.removeAllFromMap()
        
        self.printOut("Serial Viewshed Total Time: \(self.elapsedSerialTime)")
        self.printOut("\nStarting Parallel Viewshed")
        
        self.startParallelTimer()
        for obsP in observers {
            self.performParallelViewshed(obsP, viewshedGroup: viewshedGroup)
        }
        
        dispatch_group_notify(viewshedGroup, dispatch_get_main_queue()) {
            self.stopParallelTimer()
            self.printOut("Parallel Viewshed Total Time: \(self.elapsedParallelTime)")
            print("Parallel Viewshed Total Time: \(self.elapsedParallelTime)")
            self.clearTimer()
            self.printOut("Metrics Finished for \(numObservers) Observer(s).\n")
        }
        
    }
    
    
    // MARK: Fog Viewshed
    
    
    func initiateFogViewshed() {
        
        if (ConnectionManager.allWorkers.count != 1 &&
            ConnectionManager.allWorkers.count != 2 &&
            ConnectionManager.allWorkers.count != 4) {
                let message = "Fog Viewshed requires 1, 2, or 4 connected devices for the algorithms quadrant distribution."
                let alertController = UIAlertController(title: "Fog Viewshed", message: message, preferredStyle: .Alert)
                
                let cancelAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel) { (action) in
                    //print(action)
                }
                alertController.addAction(cancelAction)
                self.presentViewController(alertController, animated: true) {
                    // ...
                }
        } else {
            startFogViewshed()
        }
    }
    
    
    func performFogViewshed(observer: Observer, numberOfQuadrants: Int, whichQuadrant: Int) {
        
        print("Starting Fog Viewshed Processing on \(observer.name)...")
        
        let obsViewshed = ViewshedFog(elevation: self.hgtElevation, observer: observer, numberOfQuadrants: numberOfQuadrants, whichQuadrant: whichQuadrant)
        
        let obsResults:[[Int]] = obsViewshed.viewshedParallel()
        
        let image = self.generateViewshedImage(obsResults, hgtLocation: self.hgt.getCoordinate())
        self.pinObserverLocation(observer)
        print("\tFinished Viewshed Processing on \(observer.name).")
        self.addOverlay(image, imageLocation: self.hgtCoordinate)
    }
    
    
    func setupFogEvents() {
        
        ConnectionManager.onEvent(Event.StartViewshed){ peerID, object in
            print("Recieved request to initiate a viewshed from \(peerID.displayName)")
            
            let dict = object as! [String: NSData]
            let workArray = ViewshedWorkArray(mpcSerialized: dict["workArray"]!)
            var returnTo = ""
            // let returnMatrix = [[Int]](count:Srtm3.MAX_SIZE, repeatedValue:[Int](count:Srtm3.MAX_SIZE, repeatedValue:0))
            
            for work:ViewshedWork in workArray.array {
                returnTo = work.searchInitiator
                
                if work.assignedTo == Worker.getMe().name {
                    print("Beginning viewshed for \"\(work.whichQuadrant)\" from indecies \(work.numberOfQuadrants)")
                    self.performFogViewshed(work.getObserver(), numberOfQuadrants: work.numberOfQuadrants, whichQuadrant: work.whichQuadrant)
                }
            }
            
            print("Sending results back.")
            let result = ViewshedWork(numberOfQuadrants: 10, whichQuadrant: 10, viewshedResult: "returnMatrix", observer: self.singleRandomObserver(), assignedTo: Worker.getMe().name, searchInitiator: returnTo)
            
            ConnectionManager.sendEvent(Event.SendViewshedResult, object: ["searchResult": result])
        }
        
        
        ConnectionManager.onEvent(Event.SendViewshedResult) { peerID, object in
            print("Received Event.SendViewshedResult")
            var dict = object as! [NSString: NSData]
            let result = ViewshedWork(mpcSerialized: dict["searchResult"]!)
            
            if (result.searchInitiator == Worker.getMe().name) {
                self.responsesRecieved[peerID.displayName] = true
                // self.searchResultTotal += Int(result.searchResults) ?? 0
                print("Result recieved from \(peerID.displayName): \(result.whichQuadrant) quadrant.")
                
                // check to see if all responses have been recieved
                var allRecieved = true
                for (_, didRespond) in self.responsesRecieved {
                    if didRespond == false {
                        allRecieved = false
                        break
                    }
                }
                
                if allRecieved {
                    print("Viewshed complete.")
                }
            }
        }
    }
    
    
    func startFogViewshed() {
        
        print("Beginning viewshed")
        let numberOfPeers = ConnectionManager.allWorkers.count
        //let totalWorkUnits = MonteCristo.paragraphs.count
        let workDivision = getQuadrant(numberOfPeers)
        
        var count = 0
        var tempArray = [ViewshedWork]()
        
        
        for peer in ConnectionManager.allWorkers {
            self.responsesRecieved[peer.name] = false
            
            let currentQuadrant = workDivision[count]
            count++
            
            let work = ViewshedWork(numberOfQuadrants: numberOfPeers, whichQuadrant: currentQuadrant, viewshedResult: "emptyMatrix", observer: self.singleTestObserver(), assignedTo: peer.name, searchInitiator: Worker.getMe().name)
            
            tempArray.append(work)
            
            if peer.name == Worker.getMe().name {
                self.responsesRecieved[Worker.getMe().name] = true
                self.performFogViewshed(work.getObserver(), numberOfQuadrants: work.numberOfQuadrants, whichQuadrant: work.whichQuadrant)
                print("Found results locally out of \(numberOfPeers).")
            }
        }
        
        let workArray = ViewshedWorkArray(array: tempArray)
        print("Sending Event.StartViewshed")
        ConnectionManager.sendEvent(Event.StartViewshed, object: ["workArray": workArray])
    }
    
    
    private func getQuadrant(numberOfWorkers: Int) -> [Int] {
        var quadrants:[Int] = []

        if (numberOfWorkers == 1) {
            quadrants.append(1)
        } else if (numberOfWorkers == 2) {
            quadrants.append(1)
            quadrants.append(2)
        } else if (numberOfWorkers == 4) {
            quadrants.append(1)
            quadrants.append(2)
            quadrants.append(3)
            quadrants.append(4)
        }
        return quadrants
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
    
    
    @IBAction func startParallel(sender: AnyObject) {
        
        let viewshedGroup = dispatch_group_create()
        self.startParallelTimer()
        //  dispatch_apply(8, dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) { index in
        // let count = Int(index + 1)
        for count in 1...8 {
            
            let observer = Observer(name: String(count), x: count * 100, y: count * 100, height: 20, radius: 100, coordinate: self.hgtCoordinate)
            
            self.performParallelViewshed(observer, viewshedGroup: viewshedGroup)
        }

        dispatch_group_notify(viewshedGroup, dispatch_get_main_queue()) {
            self.stopParallelTimer()
        }
    }
    
    
    @IBAction func startSerial(sender: AnyObject) {
        self.startSerialTimer()
        
        for count in 1...8 {
            let observer = Observer(name: String(count), x: count * 100, y: count * 100, height: 20, radius: 100, coordinate: self.hgtCoordinate)
            self.performSerialViewshed(observer)
            
        }
        
        self.stopSerialTimer()
    }
    
    
    // Used to kick-off various test cases/processing
    @IBAction func randomObserver(sender: AnyObject) {
        //singleViewshed()
        
        //initiateMetricsGathering()
        
        initiateFogViewshed()
        
    }
    
    
    @IBAction func clearTimer(sender: AnyObject) {
        clearTimer()
        removeAllFromMap()
        self.centerMapOnLocation(self.hgt.getCenterLocation())
    }
    

}
