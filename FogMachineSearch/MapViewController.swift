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

    @IBOutlet weak var peerStatusLabel: UILabel!
    @IBOutlet weak var serialLabel: UILabel!
    @IBOutlet weak var parallelLabel: UILabel!
    @IBOutlet weak var mapTypeSelector: UISegmentedControl!
    
    
    var startParallelTimer: CFAbsoluteTime!
    var startSerialTimer: CFAbsoluteTime!
    var hgt: Hgt!
    var hgtCoordinate:CLLocationCoordinate2D!
    var hgtElevation:[[Double]]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        peerStatusLabel.text = "Connected to \(ConnectionManager.otherWorkers.count) peers"
        mapView.delegate = self

        let hgtFilename = "N38W077"//"N39W075"//"N38W077"

        hgt = Hgt(filename: hgtFilename)
        
        hgtCoordinate = hgt.getCoordinate()
        hgtElevation = hgt.getElevation()
        
        self.centerMapOnLocation(self.hgt.getCenterLocation())
       
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    func performParallelViewshed(observer: Observer, viewshedGroup: dispatch_group_t) {//-> [[Double]] {
        
        
        dispatch_group_enter(viewshedGroup)
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
            
            print("Starting Parallel Viewshed Processing on \(observer.name)...")
            
            
            //let initialTime = CFAbsoluteTimeGetCurrent()
            
            let obsViewshed = Viewshed(elevation: self.hgtElevation, observer: observer)
            
            let obsResults:[[Double]] = obsViewshed.viewshed()
            //print("\(observer.name) Viewshed Time: \(CFAbsoluteTimeGetCurrent() - initialTime)")
            
            
            

            dispatch_async(dispatch_get_main_queue()) {
                let image = self.displaySingleResult(obsResults, hgtCoordinate: self.hgt.getCoordinate(), observerCoordinate: observer.getObserverLocation(), name: observer.name)
                
                self.addOverlay(image, imageLocation: self.hgtCoordinate)
                
                print("\tFinished Viewshed Processing on \(observer.name).")
                
                dispatch_group_leave(viewshedGroup)
                  
           }
        }
        
        // return obsResults
        
    }
    
    
    func performSerialViewshed(observer: Observer) {
        
        print("Starting Serial Viewshed Processing on \(observer.name)...")
        
        //et initialTime = CFAbsoluteTimeGetCurrent()
        
        let obsViewshed = Viewshed(elevation: self.hgtElevation, observer: observer)
        
        let obsResults:[[Double]] = obsViewshed.viewshed()
        
        //print("\t\(observer.name) Viewshed Time: \(CFAbsoluteTimeGetCurrent() - initialTime)")
        
        
        let image = self.displaySingleResult(obsResults, hgtCoordinate: self.hgt.getCoordinate(), observerCoordinate: observer.getObserverLocation(), name: observer.name)
        
        print("\tFinished Viewshed Processing on \(observer.name).")
        self.addOverlay(image, imageLocation: self.hgtCoordinate)
    }
    
    
    func displaySingleResult(viewshedResult: [[Double]], hgtCoordinate: CLLocationCoordinate2D, observerCoordinate: CLLocationCoordinate2D, name: String) -> UIImage {
        
        //let initialTime = CFAbsoluteTimeGetCurrent()
        let resultImage = displayViewshed(viewshedResult, hgtLocation: hgtCoordinate)
        //print("\t\(name) Display Time: \(CFAbsoluteTimeGetCurrent() - initialTime)")
        
        pinObserverLocation(observerCoordinate, name: name)

        return resultImage
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
        
        //dispatch_async(dispatch_get_main_queue()) {
            self.mapView.addOverlay(overlay)
        //}
    }
    
    
    func displayViewshed(viewshed: [[Double]], hgtLocation: CLLocationCoordinate2D) -> UIImage {

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
                    data.append(Pixel(alpha: 50, red: 30, green: 230, blue: 30))
                }
            }
        }
        
        let image = imageFromArgb32Bitmap(data, width: width, height: height)
        //imageView.image = image
        //addOverlay(image, imageLocation: hgtLocation)
        return image
        
    }
    
 
    func centerMapOnLocation(location: CLLocationCoordinate2D) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location, Srtm3.DISPLAY_DIAMETER, Srtm3.DISPLAY_DIAMETER)
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
    
    
    func removeAllFromMap() {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
    }
    
    
    func startParallelTime() {
        startParallelTimer = CFAbsoluteTimeGetCurrent()
    }
    
    
    func stopParallelTime() {
        let elapsedTime = CFAbsoluteTimeGetCurrent() - startParallelTimer
        parallelLabel.text = String(format: "%.6f", elapsedTime)
    }

    
    func startSerialTime() {
        startSerialTimer = CFAbsoluteTimeGetCurrent()
    }
    
    
    func stopSerialTime() {
        let elapsedTime = CFAbsoluteTimeGetCurrent() - startSerialTimer
        serialLabel.text = String(format: "%.6f", elapsedTime)
    }

    
    func clearTime() {
        parallelLabel.text = "0"
        serialLabel.text = "0"
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
    
    
    @IBAction func startParallel(sender: AnyObject) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
            
            let viewshedGroup = dispatch_group_create()
            self.startParallelTime()
            //  dispatch_apply(8, dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) { index in
            for count in 1...8 {
                // let count = Int(index + 1)
                let observer = Observer(name: String(count), x: count * 100, y: count * 100, height: 20, radius: 100, coordinate: self.hgtCoordinate)
                
                self.performParallelViewshed(observer, viewshedGroup: viewshedGroup)
                
                
            }
            
//            dispatch_group_wait(viewshedGroup, DISPATCH_TIME_FOREVER)
//            dispatch_async(dispatch_get_main_queue()) {
            
            dispatch_group_notify(viewshedGroup, dispatch_get_main_queue()) {
                self.stopParallelTime()
            }
            
        }
    }
    
    
    @IBAction func startSerial(sender: AnyObject) {
        self.startSerialTime()
        
        for count in 1...8 {
            let observer = Observer(name: String(count), x: count * 100, y: count * 100, height: 20, radius: 100, coordinate: self.hgtCoordinate)
            self.performSerialViewshed(observer)
            
        }
        
        self.stopSerialTime()
    }
    
    
    @IBAction func randomObserver(sender: AnyObject) {
        let name = String(arc4random_uniform(10000) + 1)
        let x = Int(arc4random_uniform(700) + 200)
        let y = Int(arc4random_uniform(700) + 200)
        let observer = Observer(name: name, x: x, y: y, height: 20, radius: 300, coordinate: self.hgtCoordinate)
        self.performSerialViewshed(observer)
    }
    
    
    @IBAction func clearTimer(sender: AnyObject) {
        clearTime()
        removeAllFromMap()
        self.centerMapOnLocation(self.hgt.getCenterLocation())
    }
    

}
