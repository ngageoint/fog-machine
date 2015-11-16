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

    @IBOutlet weak var mapView: MKMapView!

    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var timerStart: UIButton!

    @IBOutlet weak var mapTypeSelector: UISegmentedControl!
    
    
    var startTimer: CFAbsoluteTime!
    var hgtElevation:[[Double]]!
    var filename:String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        
        filename = "N39W075"//"N39W075"//"N38W077"

        hgtElevation = readHgt(filename)
       
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // Height files have the extension .HGT and are signed two byte integers. The
    // bytes are in Motorola "big-endian" order with the most significant byte first
    // Data voids are assigned the value -32768 and are ignored (no special processing is done)
    // SRTM3 files contain 1201 lines and 1201 samples
    func readHgt(filename: String) -> [[Double]] {
        
        let path = NSBundle.mainBundle().pathForResource(filename, ofType: "hgt")
        let url = NSURL(fileURLWithPath: path!)
        let data = NSData(contentsOfURL: url)!
        
        var elevationMatrix = [[Double]](count:Hgt.MAX_SIZE, repeatedValue:[Double](count:Hgt.MAX_SIZE, repeatedValue:0))
        
        let dataRange = NSRange(location: 0, length: data.length)
        var elevation = [Int16](count: data.length, repeatedValue: 0)
        data.getBytes(&elevation, range: dataRange)
        
        
        var row = 0
        var column = 0
        for (var cell = 0; cell < data.length; cell+=1) {
            elevationMatrix[row][column] = Double(elevation[cell].bigEndian)
            
            column++
            
            if column >= Hgt.MAX_SIZE {
                column = 0
                row++
            }
            
            if row >= Hgt.MAX_SIZE {
                break
            }
        }
        
        return elevationMatrix
    }

    
    func performParallelViewshed(observer: Observer) {//-> [[Double]] {
        
        
        
        
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            
            print("Starting Viewshed Processing on \(observer.name)...please wait patiently.")
            
            
            let initialTime = CFAbsoluteTimeGetCurrent()
            
            let obsViewshed = Viewshed(elevation: self.hgtElevation, observer: observer, hgtFilename: self.filename)
            
            let obsResults:[[Double]] = obsViewshed.viewshed()
            print("\(observer.name) Viewshed Time: \(CFAbsoluteTimeGetCurrent() - initialTime)")
            
            
            
            dispatch_async(dispatch_get_main_queue()) {
                
                self.displayResults(obsResults, hgtCoordinate: obsViewshed.getHgtCoordinate(), hgtCenterCoordinate: obsViewshed.getHgtCenterLocation(), observerCoordinate: obsViewshed.getObserverLocation(), name: observer.name
                )
                print("Finished Viewshed Processing on \(observer.name).")
                
                
                
                
            }
        }
        
        
        
        
        
        

        
        
        
        
        
        // return obsResults
        
    }
    
    
    
    func performSerialViewshed(observer: Observer) {
        
        print("Starting Viewshed Processing on \(observer.name)...")
        
        let initialTime = CFAbsoluteTimeGetCurrent()
        
        let obsViewshed = Viewshed(elevation: self.hgtElevation, observer: observer, hgtFilename: self.filename)
        
        let obsResults:[[Double]] = obsViewshed.viewshed()
        print("\t\(observer.name) Viewshed Time: \(CFAbsoluteTimeGetCurrent() - initialTime)")
        
        self.displayResults(obsResults, hgtCoordinate: obsViewshed.getHgtCoordinate(), hgtCenterCoordinate: obsViewshed.getHgtCenterLocation(), observerCoordinate: obsViewshed.getObserverLocation(), name: observer.name
        )
        print("Finished Viewshed Processing on \(observer.name).")
        
    }
    
    
    func displayResults(viewshedResult: [[Double]], hgtCoordinate: CLLocationCoordinate2D, hgtCenterCoordinate: CLLocationCoordinate2D, observerCoordinate: CLLocationCoordinate2D, name: String) {
        
        let initialTime = CFAbsoluteTimeGetCurrent()
        //Potentially combine multiple results
        displayViewshed(viewshedResult, hgtLocation: hgtCoordinate)
        print("\t\(name) Display Time: \(CFAbsoluteTimeGetCurrent() - initialTime)")
        
        centerMapOnLocation(hgtCenterCoordinate)
        pinObserverLocation(observerCoordinate, name: name)

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
        
        mapView.addOverlay(overlay)
    }
    
    
    func displayViewshed(viewshed: [[Double]], hgtLocation: CLLocationCoordinate2D) {

        let width = viewshed[0].count
        let height = viewshed.count
        var data: [Pixel] = []
        
        // CoreGraphics expects pixel data as rows, not columns.
        for(var y = 0; y < width; y++) {
            for(var x = 0; x < height; x++) {
                
                let cell = viewshed[y][x]
                if(cell == 0) {
                    data.append(Pixel(alpha: 75, red: 0, green: 0, blue: 0))
                } else if (cell == -1){
                    data.append(Pixel(alpha: 75, red: 126, green: 0, blue: 126))
                } else {
                    data.append(Pixel(alpha: 75, red: 0, green: 255, blue: 0))
                }
            }
        }
        
        let image = imageFromArgb32Bitmap(data, width: width, height: height)
        //imageView.image = image
        addOverlay(image, imageLocation: hgtLocation)
        
    }
    
 
    func centerMapOnLocation(location: CLLocationCoordinate2D) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location, Hgt.DISPLAY_DIAMETER, Hgt.DISPLAY_DIAMETER)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    
    func pinObserverLocation(location: CLLocationCoordinate2D, name: String) {
        
        let dropPin = MKPointAnnotation()
        dropPin.coordinate = location
        dropPin.title = name
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
    
    
    func removeAllAnnotations() {
        mapView.removeAnnotations(mapView.annotations)
    }
    
    
    func removeAllOverlays() {
        mapView.removeOverlays(mapView.overlays)
    }
    
    
    func startTime() {
        startTimer = CFAbsoluteTimeGetCurrent()
    }

    
    func stopTime() {
        let elapsedTime = CFAbsoluteTimeGetCurrent() - startTimer
        timerLabel.text = String(format: "%.6f", elapsedTime)
    }
    
    
    func clearTime() {
        timerLabel.text = "0"
    }
    
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
    
    @IBAction func startTimer(sender: AnyObject) {
        startTime()
        
        
        
        let newObs = Observer(name: "Observer 1", x: 600, y: 200, height: 30, radius: 200)
        performParallelViewshed(newObs)

        let newObs2 = Observer(name: "Observer 2", x: 1000, y: 700, height: 30, radius: 200)
        performParallelViewshed(newObs2)

        let newObs3 = Observer(name: "Observer 3", x: 200, y: 700, height: 30, radius: 200)
        performParallelViewshed(newObs3)
        
        let newObs4 = Observer(name: "Observer 4", x: 200, y: 200, height: 30, radius: 200)
        performParallelViewshed(newObs4)

        
        
//        let newObs = Observer(name: "Observer 1", x: 600, y: 200, height: 30, radius: 200)
//        performSerialViewshed(newObs)
//        
//        let newObs2 = Observer(name: "Observer 2", x: 1000, y: 700, height: 30, radius: 200)
//        performSerialViewshed(newObs2)
//        
//        let newObs3 = Observer(name: "Observer 3", x: 200, y: 700, height: 30, radius: 200)
//        performSerialViewshed(newObs3)
//        
//        let newObs4 = Observer(name: "Observer 4", x: 200, y: 200, height: 30, radius: 200)
//        performSerialViewshed(newObs4)
        
        
        stopTime()
    }
    
    @IBAction func clearTimer(sender: AnyObject) {
        clearTime()
        removeAllAnnotations()
        removeAllOverlays()
    }
    

}
