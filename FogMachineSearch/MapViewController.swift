//
//  MapViewController.swift
//  FogMachineSearch
//
//  Created by Chris Wasko on 11/4/15.
//  Copyright © 2015 NGA. All rights reserved.
//

import UIKit
import MapKit

struct PixelData {
    var a: UInt8
    var r: UInt8
    var g: UInt8
    var b: UInt8
}

class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!

    @IBOutlet weak var imageView: UIImageView!
    
    let regionRadius: CLLocationDistance = 100000

    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        
        
        let filename = "N39W075"//"N39W075"//"N38W077"
        
        let hgtElevation:[[Double]] = readHgt(filename)
        
        let fileLocation = getCoordinateFromFilename(filename)

        centerMapOnLocation(CLLocationCoordinate2DMake(fileLocation.latitude + Hgt.CENTER_OFFSET,
            fileLocation.longitude + Hgt.CENTER_OFFSET))
      
        
        print("Starting Viewshed...please wait patiently.")
    
        
        //var elevationMatrix = [[Double]](count:10, repeatedValue:[Double](count:10, repeatedValue:1))
        
        // 0,0 is top left
        let obsX = 600
        let obsY = 200
        let obsHeight = 30
        let viewRadius = 600 //problem in viewshed algorithm, this needs to be 600 for now
        
        let view = Viewshed()
        var viewshed:[[Double]] = view.viewshed(hgtElevation, obsX: obsX, obsY: obsY, obsHeight: obsHeight, viewRadius: viewRadius)
        
        print("Preparing PixelData.")
        
        let width = viewshed[0].count
        let height = viewshed.count
        var data: [PixelData] = []

        // CoreGraphics expects pixel data as rows, not columns.
        for(var y = 0; y < width; y++) {
            for(var x = 0; x < height; x++) {
                
                let cell = viewshed[y][x]
                if(cell == 0) {
                    data.append(PixelData(a: 75, r: 0, g: 0, b: 0))
                } else if (cell == -1){
                    data.append(PixelData(a: 75, r: 0, g: 0, b: 255))
                } else {
                    data.append(PixelData(a: 75, r: 0, g: 255, b: 0))
                }
            }
        }
        
        
        print("Rendering image.")
        
        let image = imageFromArgb32Bitmap(data, width: width, height: height)
        imageView.image = image
        addOverlay(image, imageLocation: fileLocation)
        


        let observerLocation = CLLocationCoordinate2DMake(
            fileLocation.latitude + 1 - (Hgt.CELL_SIZE * Double(obsX - 1)) + Hgt.LATITUDE_CELL_CENTER,
            fileLocation.longitude + (Hgt.CELL_SIZE * Double(obsY - 1) + Hgt.LONGITUDE_CELL_CENTER)
        )

        // Drop a pin
        let dropPin = MKPointAnnotation()
        dropPin.coordinate = observerLocation
        dropPin.title = "Observer 1"
        mapView.addAnnotation(dropPin)
        
        
        
//
//        
//        print("Finished Viewshed calculation...rendering a bunch of squares")
//  
//        
//        let startLat = 38.0//.97898180980364
//        let startLon = -77.0//.44147717649722
//        var currLat = startLat
//        var currLon = startLon
//        let size = 0.00083
//        var countRow = 0
//        var countCol = 0
//        var count = 0 //hardcoded for testing
//        var iterator = 0 //hardcoded for testing
////        for row in viewshed.reverse() {
//        while ( iterator < 20) {
//            currLon = startLon
//            countCol = 0
//            //for _ in row { //column
//            count = 0
//            while ( count < 20) {
//                if viewshed[countRow][countCol] == -1 {
//                    makeCell(UIColor.purpleColor(), lat: currLat, lon: currLon, size: size)
//                } else if viewshed[countRow][countCol] == 1 {
//                    makeCell(UIColor.greenColor(), lat: currLat, lon: currLon, size: size)
//                } else if viewshed[countRow][countCol] == 0 {
//                    makeCell(UIColor.redColor(), lat: currLat, lon: currLon, size: size)
//                }
//                
//                //makeGridSquare(currLat, lon: currLon, size: size)
//
//                currLon = currLon + size
//                countCol++
//                count++
//            }
//           // }
//            currLat = currLat + size
//            countRow++
//            iterator++
//            print("Rendered row \(countRow)")
//        }
        
        print("Pixel renderation complete!")
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

    
    
    func imageFromArgb32Bitmap(pixels:[PixelData], width: Int, height: Int)-> UIImage {
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo:CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedFirst.rawValue)
        let bitsPerComponent:Int = 8
        let bitsPerPixel:Int = 32
        let bytesPerRow = width * Int(sizeof(PixelData))
        
        // assert(pixels.count == Int(width * height))
        
        var data = pixels // Copy to mutable []
        let length = data.count * sizeof(PixelData)
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
    
    
    func mergeTwoImages(image1: UIImage, image2: UIImage, currentHeight: Int) -> UIImage {
        let topImage = image1
        let bottomImage = image2
        let newHeight = 50
        let size = CGSize(width: 300, height: currentHeight + newHeight)
        UIGraphicsBeginImageContext(size)
        
        let areaSize = CGRect(x: 0, y: 0, width: size.width, height: CGFloat(currentHeight))
        topImage.drawInRect(areaSize)
        let areaSize2 = CGRect(x: 0, y: CGFloat(currentHeight), width: size.width, height: CGFloat(newHeight))
        bottomImage.drawInRect(areaSize2)//, blendMode: CGBlendMode.Normal, alpha: 1.0)

//        let areaSize = CGRect(x: 0, y: 0, width: size.width/2, height: size.height)
//        bottomImage.drawInRect(areaSize)
//        let areaSize2 = CGRect(x: 150, y: 0, width: size.width/2, height: size.height)
//        topImage.drawInRect(areaSize2, blendMode: CGBlendMode.Normal, alpha: 0.8)
        
        
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
        
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
    
 
    
//    func imageManipulation() {
//        
//        var imageRep: NSBitmapImageRep = self.screenShot()
//        var data: UInt8 = imageRep.bitmapData()
//
//        var width: Int = imageRep.pixelsWide()
//        var height: Int = imageRep.pixelsHight()
//        var rowBytes: Int = imageRep.bytesPerRow()
//        var pixels: Character = imageRep.bitmapData()
//        var row: Int
//        var col: Int
//        for (row = 0; row < height; row++) {
//            var rowStart: UInt8 = (pixels + (row * rowBytes))
//            var nextChannel: UInt8 = rowStart
//            for (col = 0; col < width; col++) {
//                var red: UInt8
//                var green: UInt8
//                var blue: UInt8
//                var alpha: UInt8
//                red = nextChannel
//                nextChannel++
//                green = nextChannel
//                nextChannel++
//                blue = nextChannel
//                nextChannel++
//                alpha = nextChannel
//
//            }
//        }
//        
//        let image = CII
//        
//        
//        //////////
//        //////////
//
//        
////        var rgba: Character = malloc(width * height * 4)
////        for var i = 0; i < width * height; ++i {
////            rgba[4 * i] = myBuffer[3 * i]
////            rgba[4 * i + 1] = myBuffer[3 * i + 1]
////            rgba[4 * i + 2] = myBuffer[3 * i + 2]
////            rgba[4 * i + 3] = 0
////        }
////        var colorSpace: CGColorSpaceRef = CGColorSpaceCreateDeviceRGB()
////        var bitmapContext: CGContextRef = CGBitmapContextCreate(rgba, width, height, 8, 4 * width, colorSpace, kCGImageAlphaNoneSkipLast)
////        CFRelease(colorSpace)
////        var cgImage: CGImageRef = CGBitmapContextCreateImage(bitmapContext)
////        var url: CFURLRef = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, CFSTR(image.png), kCFURLPOSIXPathStyle, false)
////        var type: CFString = kUTTypePNG
////        var dest: CGImageDestinationRef = CGImageDestinationCreateWithURL(url, type, 1, 0)
////        CGImageDestinationAddImage(dest, cgImage, 0)
////        CFRelease(cgImage)
////        CFRelease(bitmapContext)
////        CGImageDestinationFinalize(dest)
////        free(rgba)
//
//        
//        
//        
//    }
    
    
    func makeCell(color: UIColor, lat: Double, lon: Double, size: Double) {
        let lowerLeftLat = lat
        let lowerRightLat = lat
        let upperRightLat = lat + size
        let upperLeftLat = lat + size
        
        let lowerLeftLon = lon
        let lowerRightLon = lon + size
        let upperRightLon = lon  + size
        let upperLeftLon = lon
        
        
        var square = [
            CLLocationCoordinate2DMake(lowerLeftLat, lowerLeftLon),
            CLLocationCoordinate2DMake(lowerRightLat, lowerRightLon),
            CLLocationCoordinate2DMake(upperRightLat, upperRightLon),
            CLLocationCoordinate2DMake(upperLeftLat, upperLeftLon),
            CLLocationCoordinate2DMake(lowerLeftLat, lowerLeftLon)
        ]
        let squarePolygon = Cell(coordinates: &square, count: square.count)
        squarePolygon.color = color
        //let squarePolygon: MKPolygon = MKPolygon(coordinates: &square, count: square.count)
        mapView.addOverlay(squarePolygon)

    }
    
    
    func makeGridSquare(lat: Double, lon: Double, size: Double) {
        
        let lowerLeftLat = lat
        let lowerRightLat = lat
        let upperRightLat = lat + size
        let upperLeftLat = lat + size
        
        let lowerLeftLon = lon
        let lowerRightLon = lon + size
        let upperRightLon = lon  + size
        let upperLeftLon = lon
        
        
        var square = [
            CLLocationCoordinate2DMake(lowerLeftLat, lowerLeftLon),
            CLLocationCoordinate2DMake(lowerRightLat, lowerRightLon),
            CLLocationCoordinate2DMake(upperRightLat, upperRightLon),
            CLLocationCoordinate2DMake(upperLeftLat, upperLeftLon),
            CLLocationCoordinate2DMake(lowerLeftLat, lowerLeftLon)
        ]
        
        let squarePolygon: MKPolygon = MKPolygon(coordinates: &square, count: square.count)
        mapView.addOverlay(squarePolygon)
    }
    
    
    func centerMapOnLocation(location: CLLocationCoordinate2D) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
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
