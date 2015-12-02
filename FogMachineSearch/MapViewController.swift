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

    @IBOutlet weak var mapTypeSelector: UISegmentedControl!
    @IBOutlet weak var logBox: UITextView!
    
    
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
    var viewshedResults: [[Int]]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self

        let hgtFilename = "N39W075"//"N39W075"//"N38W077"
        metricsOutput = ""
        
        logBox.text = "Connected to \(ConnectionManager.otherWorkers.count) peers.\n"
        logBox.editable = false

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
    
    
    func singleViewshed(algorithm: ViewshedAlgorithm) {
        self.performSerialViewshed(singleRandomObserver(), algorithm: algorithm)
    }
    
    
    func performParallelViewshed(observer: Observer, algorithm: ViewshedAlgorithm, viewshedGroup: dispatch_group_t) {
        
        dispatch_group_enter(viewshedGroup)
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
            
            print("Starting Parallel Viewshed Processing on \(observer.name).")
            var obsResults:[[Int]]!
            if (algorithm == ViewshedAlgorithm.FranklinRay) {
                let obsViewshed = Viewshed(elevation: self.hgtElevation, observer: observer)
                obsResults = obsViewshed.viewshed()
            } else if (algorithm == ViewshedAlgorithm.VanKreveld) {
                // running Van Kreveld viewshed.
                let kreveld: KreveldViewshed = KreveldViewshed()
                let demObj: DemData = DemData(demMatrix: self.hgtElevation)
                let observerPoints: ElevationPoint = ElevationPoint (x:observer.x, y: observer.y)
                obsResults = kreveld.parallelKreveld(demObj, observPt: observerPoints, radius: observer.radius, numQuadrants: 1, quadrant2Calc: 0)
                //obsResults = kreveld.calculateViewshed(demObj, observPt: observerPoints, radius: observer.radius, numQuadrants: 0, quadrant2Calc: 0)
            }
            dispatch_async(dispatch_get_main_queue()) {
                
                print("\tFinished Viewshed Processing on \(observer.name).")
                
                self.pinObserverLocation(observer)
                let image = self.generateViewshedImage(obsResults, hgtLocation: self.hgt.getCoordinate())
                self.addOverlay(image, imageLocation: self.hgtCoordinate)
                
                dispatch_group_leave(viewshedGroup)
           }
        }
    }
    
    
    func performSerialViewshed(observer: Observer, algorithm: ViewshedAlgorithm) {
        
        print("Starting Serial Viewshed Processing on \(observer.name).")

        var obsResults:[[Int]]!
        if (algorithm == ViewshedAlgorithm.FranklinRay) {
            let obsViewshed = Viewshed(elevation: self.hgtElevation, observer: observer)
            obsResults = obsViewshed.viewshed()
        } else if (algorithm == ViewshedAlgorithm.VanKreveld) {
            let kreveld: KreveldViewshed = KreveldViewshed()
            let demObj: DemData = DemData(demMatrix: self.hgtElevation)
           // observer.radius = 200 // default radius 100
            // set the added observer height 
            let observerPoints: ElevationPoint = ElevationPoint (x:observer.x, y: observer.y, h: Double(observer.height))
            obsResults = kreveld.parallelKreveld(demObj, observPt: observerPoints, radius: observer.radius, numQuadrants: 1, quadrant2Calc: 0)
            //obsResults = kreveld.calculateViewshed(demObj, observPt: observerPoints, radius: observer.radius, numQuadrants: 0, quadrant2Calc: 0)
        }
        
        print("\tFinished Viewshed Processing on \(observer.name).")
        
        self.pinObserverLocation(observer)
        let image = self.generateViewshedImage(obsResults, hgtLocation: self.hgt.getCoordinate())
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
    
    
    func mergeViewshedResults(viewshedOne: [[Int]], viewshedTwo: [[Int]]) -> [[Int]] {
        var viewshedResult = viewshedOne
        
        for (var row = 0; row < viewshedOne.count; row++) {
            for (var column = 0; column < viewshedOne[row].count; column++) {
                if (viewshedTwo[row][column] == 1) {
                    viewshedResult[row][column] = 1
                }
            }
        }
        
        return viewshedResult
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
        self.printOut("Parallel Time: " + String(format: "%.6f", elapsedParallelTime))
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
        self.printOut("Serial Time: " + String(format: "%.6f", elapsedSerialTime))
        if toPrint {
            log("Observer \(observer):\t\(elapsedSerialTime)")
        }
        return elapsedSerialTime
    }

    
    func clearTimer() {
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
        print(output)
        //metricsOutput = metricsOutput + "\n" + output
        logBox.text = logBox.text + "\n" + output
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
        let options = Options.sharedInstance
        
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
                radius = options.radius//count + 100 //If the radius grows substantially larger then the parallel threads will finish sequentially
            }
            
            let observer = Observer(name: name, x: x, y: y, height: height, radius: radius, coordinate: self.hgtCoordinate)
            self.printOut("\tObserver \(name): x: \(x)\ty: \(y)\theight: \(height)\tradius: \(radius)")
            observers.append(observer)
        }
        
        //Starting serial before the parallel so the parallel will not be running when the serial runs
        self.printOut("\nStarting Serial Viewshed")
        
        self.startSerialTimer()
        for obs in observers {
            self.performSerialViewshed(obs, algorithm: options.viewshedAlgorithm)
        }
        self.stopSerialTimer()
        self.removeAllFromMap()
        
        self.printOut("Serial Viewshed Total Time: \(self.elapsedSerialTime)")
        self.printOut("\nStarting Parallel Viewshed")
        
        self.startParallelTimer()
        for obsP in observers {
            self.performParallelViewshed(obsP, algorithm: options.viewshedAlgorithm, viewshedGroup: viewshedGroup)
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

        // Check does nothing, is there in case it is needed once the Fog device requirements are specified.
        if (ConnectionManager.allWorkers.count < 0) {
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
            viewshedResults = [[Int]](count:Srtm3.MAX_SIZE, repeatedValue:[Int](count:Srtm3.MAX_SIZE, repeatedValue:0))
            logBox.text = ""
            startFogViewshed()
        }
    }
    
    
    func performFogViewshed(observer: Observer, numberOfQuadrants: Int, whichQuadrant: Int) -> [[Int]]{
        
        printOut("Starting Fog Viewshed Processing on \(observer.name)...")
        let options = Options.sharedInstance
        var obsResults:[[Int]]!
        
        if (options.viewshedAlgorithm == ViewshedAlgorithm.FranklinRay) {
            let obsViewshed = ViewshedFog(elevation: self.hgtElevation, observer: observer, numberOfQuadrants: numberOfQuadrants, whichQuadrant: whichQuadrant)
            obsResults = obsViewshed.viewshedParallel()
        } else if (options.viewshedAlgorithm == ViewshedAlgorithm.VanKreveld) {
            let kreveld: KreveldViewshed = KreveldViewshed()
            let demObj: DemData = DemData(demMatrix: self.hgtElevation)
            //let x: Int = work.getObserver().x
            let observerPoints: ElevationPoint = ElevationPoint (x: observer.x, y: observer.y, h: Double(observer.height))
            obsResults = kreveld.parallelKreveld(demObj, observPt: observerPoints, radius: observer.radius, numQuadrants: numberOfQuadrants, quadrant2Calc: whichQuadrant)
        }
        
        printOut("\tFinished Viewshed Processing on \(observer.name).")

        self.pinObserverLocation(observer)
        
        return obsResults
    }
    
    
    func setupFogEvents() {
        
        ConnectionManager.onEvent(Event.StartViewshed){ peerID, object in
            self.printOut("Recieved request to initiate a viewshed from \(peerID.displayName)")
            
            let dict = object as! [String: NSData]
            let workArray = ViewshedWorkArray(mpcSerialized: dict["workArray"]!)
            //var returnTo = ""
            // let returnMatrix = [[Int]](count:Srtm3.MAX_SIZE, repeatedValue:[Int](count:Srtm3.MAX_SIZE, repeatedValue:0))
            //var viewshedResults: [[Int]] = []
            let options = Options.sharedInstance
            
            for work:ViewshedWork in workArray.array {
                //returnTo = work.searchInitiator
                
                if work.assignedTo == Worker.getMe().name {
                    self.printOut("\tBeginning viewshed for \(work.whichQuadrant) from \(work.numberOfQuadrants)")
                    
                    
                    if (options.viewshedAlgorithm == ViewshedAlgorithm.FranklinRay) {
                        self.viewshedResults = self.performFogViewshed(work.getObserver(), numberOfQuadrants: work.numberOfQuadrants, whichQuadrant: work.whichQuadrant)
                    } else if (options.viewshedAlgorithm == ViewshedAlgorithm.VanKreveld) {
                        let kreveld: KreveldViewshed = KreveldViewshed()
                        let demObj: DemData = DemData(demMatrix: self.hgtElevation)
                        //let x: Int = work.getObserver().x
                        let observerPoints: ElevationPoint = ElevationPoint (x: work.getObserver().x, y: work.getObserver().x, h: Double(work.getObserver().height))
                        self.viewshedResults = kreveld.parallelKreveld(demObj, observPt: observerPoints, radius: work.getObserver().radius, numQuadrants: work.numberOfQuadrants, quadrant2Calc: work.whichQuadrant)
                    }
                    
                    self.printOut("\tSending results back.")
                
                    
                    let image = self.generateViewshedImage(self.viewshedResults, hgtLocation: self.hgt.getCoordinate())
                    self.addOverlay(image, imageLocation: self.hgtCoordinate)
                    
                    let result = ViewshedResult(viewshedResult: image,//self.viewshedResults,
                        assignedTo: work.assignedTo, searchInitiator: work.searchInitiator)

                    //ViewshedWork(numberOfQuadrants: work.numberOfQuadrants, whichQuadrant: work.whichQuadrant, viewshedResult: viewshedResults, observer: self.singleRandomObserver(), assignedTo: Worker.getMe().name, searchInitiator: returnTo)
             
                    if (work.searchInitiator != Worker.getMe().name) {
                        self.printOut("\tDisplay result locally on \(work.assignedTo)")
                        let image = self.generateViewshedImage(self.viewshedResults, hgtLocation: self.hgt.getCoordinate())
                        self.addOverlay(image, imageLocation: self.hgtCoordinate)
                    }
                    self.printOut("\tSending Event.SendViewshedResults from \(work.assignedTo)")
                    ConnectionManager.sendEvent(Event.SendViewshedResult, object: ["viewshedResult": result])
                    
                    break
                }
            }
            
        }
        
        
        ConnectionManager.onEvent(Event.SendViewshedResult) { peerID, object in
            self.printOut("Received Event.SendViewshedResult")
            var dict = object as! [NSString: NSData]
            let result = ViewshedResult(mpcSerialized: dict["viewshedResult"]!)
            
            if (result.searchInitiator == Worker.getMe().name) {
                self.responsesRecieved[peerID.displayName] = true
                // self.searchResultTotal += Int(result.searchResults) ?? 0
                self.printOut("\tResult recieved from \(peerID.displayName).")
                
               // self.viewshedResults = self.mergeViewshedResults(self.viewshedResults, viewshedTwo: result.viewshedResult)
                
                self.addOverlay(result.viewshedResult, imageLocation: self.hgtCoordinate)
                
                
                self.printOut("\tFinished merging results")
                // check to see if all responses have been recieved
                var allRecieved = true
                for (_, didRespond) in self.responsesRecieved {
                    if didRespond == false {
                        allRecieved = false
                        break
                    }
                }
                self.printOut("\tChecked if all received")
                if allRecieved {
                    print("\tAll received")
                    
                    //let image = self.generateViewshedImage(self.viewshedResults, hgtLocation: self.hgt.getCoordinate())
                    //self.addOverlay(image, imageLocation: self.hgtCoordinate)
                    
                    self.printOut("Viewshed complete.")
                }
            }
        }
    }
    
    
    func startFogViewshed() {
        
        printOut("Beginning viewshed")
        let numberOfPeers = ConnectionManager.allWorkers.count
        //let totalWorkUnits = MonteCristo.paragraphs.count
        let workDivision = getQuadrant(numberOfPeers)
        
        var count = 0
        var tempArray = [ViewshedWork]()
        
        
        for peer in ConnectionManager.allWorkers {
            self.responsesRecieved[peer.name] = false
            
            let currentQuadrant = workDivision[count]
            count++
            let observer = singleTestObserver()

            
            if peer.name == Worker.getMe().name {
                self.printOut("\tBeginning viewshed locally for \(currentQuadrant) from \(numberOfPeers)")
                
                self.responsesRecieved[Worker.getMe().name] = true
                self.viewshedResults = self.performFogViewshed(observer, numberOfQuadrants: numberOfPeers, whichQuadrant: currentQuadrant)
                //if (numberOfPeers < 2) {
                    let image = self.generateViewshedImage(viewshedResults, hgtLocation: self.hgt.getCoordinate())
                    self.addOverlay(image, imageLocation: self.hgtCoordinate)
               // }
                printOut("\tFound results locally out of \(numberOfPeers).")
            }
            
            let work = ViewshedWork(numberOfQuadrants: numberOfPeers, whichQuadrant: currentQuadrant, viewshedResult: viewshedResults, observer: observer, assignedTo: peer.name, searchInitiator: Worker.getMe().name)
            
            
            
            tempArray.append(work)
            
        }
        
        let workArray = ViewshedWorkArray(array: tempArray)
        
        printOut("\tSending Event.StartViewshed")
        ConnectionManager.sendEvent(Event.StartViewshed, object: ["workArray": workArray])

    }


    private func getQuadrant(numberOfWorkers: Int) -> [Int] {
        var quadrants:[Int] = []

        for var count = 0; count < numberOfWorkers; count++ {
            quadrants.append(count + 1)
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
        let options = Options.sharedInstance
        self.startParallelTimer()
        //  dispatch_apply(8, dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) { index in
        // let count = Int(index + 1)
        for count in 1...8 {
            
            let observer = Observer(name: String(count), x: count * 100, y: count * 100, height: 20, radius: options.radius, coordinate: self.hgtCoordinate)
            
            self.performParallelViewshed(observer, algorithm: options.viewshedAlgorithm, viewshedGroup: viewshedGroup)
        }

        dispatch_group_notify(viewshedGroup, dispatch_get_main_queue()) {
            self.stopParallelTimer()
        }
    }
    
    
    @IBAction func startSerial(sender: AnyObject) {
        
        let options = Options.sharedInstance
        self.startSerialTimer()
        
        for count in 1...8 {
            let observer = Observer(name: String(count), x: count * 100, y: count * 100, height: 20, radius: options.radius, coordinate: self.hgtCoordinate)
            //let observer = Observer(name: String(count), x: 8 * 100, y: 8 * 100, height: 20, radius: options.radius, coordinate:self.hgtCoordinate)
            self.performSerialViewshed(observer, algorithm: options.viewshedAlgorithm)
            
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
        self.logBox.text = ""
    }
    

}
