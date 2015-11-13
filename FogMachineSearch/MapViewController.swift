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

    @IBOutlet weak var imageView: UIImageView!

    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        
    
        print("Starting Viewshed Processing...please wait patiently.")
        
        
        let filename = "N39W075"//"N39W075"//"N38W077"
        
        let hgtElevation:[[Double]] = readHgt(filename)
        let fileLocation = getCoordinateFromFilename(filename)

        centerMapOnLocation(CLLocationCoordinate2DMake(fileLocation.latitude + Hgt.CENTER_OFFSET,
            fileLocation.longitude + Hgt.CENTER_OFFSET))
       
    
        // 0,0 is top left
        let obsX = 600
        let obsY = 200
        let obsHeight = 30
        let viewRadius = 600 //problem in viewshed algorithm, this needs to be 600 for now
        
        let observerLocation = CLLocationCoordinate2DMake(
            fileLocation.latitude + 1 - (Hgt.CELL_SIZE * Double(obsX - 1)) + Hgt.LATITUDE_CELL_CENTER,
            fileLocation.longitude + (Hgt.CELL_SIZE * Double(obsY - 1) + Hgt.LONGITUDE_CELL_CENTER)
        )
        let observerName = "Observer 1"
        pinObserverLocation(observerLocation, name: observerName)
        
        let view = Viewshed()
        let viewshed:[[Double]] = view.viewshed(hgtElevation, obsX: obsX, obsY: obsY, obsHeight: obsHeight, viewRadius: viewRadius)
        
        displayViewshed(viewshed, hgtLocation: fileLocation)
        
        print("Pixel renderation complete!")
        
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func displayViewshed(viewshed: [[Double]], hgtLocation: CLLocationCoordinate2D) {
        
        print("Preparing PixelData.")
        
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
        
        print("Rendering image.")
        
        let image = imageFromArgb32Bitmap(data, width: width, height: height)
        imageView.image = image
        addOverlay(image, imageLocation: hgtLocation)
        
    }
    
    
    // File names refer to the latitude and longitude of the lower left corner of
    // the tile - e.g. N37W105 has its lower left corner at 37 degrees north
    // latitude and 105 degrees west longitude
    func getCoordinateFromFilename(filename: String) -> CLLocationCoordinate2D {
        
        let northSouth = filename.substringWithRange(Range<String.Index>(start: filename.startIndex,end: filename.startIndex.advancedBy(1)))
        let latitudeValue = filename.substringWithRange(Range<String.Index>(start: filename.startIndex.advancedBy(1),end: filename.startIndex.advancedBy(3)))
        let westEast = filename.substringWithRange(Range<String.Index>(start: filename.startIndex.advancedBy(3),end: filename.startIndex.advancedBy(4)))
        let longitudeValue = filename.substringWithRange(Range<String.Index>(start: filename.startIndex.advancedBy(4),end: filename.endIndex))
        
        var latitude:Double = Double(latitudeValue)!
        var longitude:Double = Double(longitudeValue)!
        
        if (northSouth.uppercaseString == "S") {
            latitude = latitude * -1.0
        }
        
        if (westEast.uppercaseString == "W") {
            longitude = longitude * -1.0
        }
    
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
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
            elevationMatrix[row][column] = Double(elevation[cell].bigEndian)//Double(bigEndianOrder)
            
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
