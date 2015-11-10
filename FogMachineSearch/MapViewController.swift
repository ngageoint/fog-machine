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
        
        let initialLocation = CLLocation(latitude:  38.0, longitude: -77.0)
        centerMapOnLocation(initialLocation)
      
        print("Starting Viewshed...please wait patiently.")
        
        
        researchForImageOverlay()
        
        
        
        //let hgtElevationMatrix:[[Double]] = readHgt()
        
        

        //Testing purposes
        //var elevationMatrix = [[Double]](count:10, repeatedValue:[Double](count:10, repeatedValue:1))
        //let obsX = 600
        //let obsY = 600
        //let obsHeight = 3
        //let viewRadius = 599
        //print("Elevation Matrix")
        //elevationMatrix[4][4] = 10 //causes top right of printed viewshed to be 0
        //elevationMatrix[3][4] = 10 //causes 2nd, 3rd and 4th from top right to be 0
        
       // let view = Viewshed()
       // var viewshed:[[Double]] = view.viewshed(hgtElevationMatrix, obsX: obsX, obsY: obsY, obsHeight: obsHeight, viewRadius: viewRadius)
        
        //var pixelViewshed = convertDoubleToPixel(viewshed)
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
        
        print("Bunch of squares renderation complete!")
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    func readHgt() -> [[Double]] {
        
        let path = NSBundle.mainBundle().pathForResource("N38W077", ofType: "hgt")
        let url = NSURL(fileURLWithPath: path!)
        let data = NSData(contentsOfURL: url)!
        
        
//        
//        //let randomData = generateRandomData(256 * 1024)
//        let stream = NSInputStream(data: data)
//        stream.open() // IMPORTANT
//        var readBuffer = Array<UInt8>(count: 1200 * 1200, repeatedValue: 0)
//        var totalBytesRead = 0
//        while (totalBytesRead < data.length)
//        {
//            let numberOfBytesRead = stream.read(&readBuffer, maxLength: readBuffer.count)
//            // Do something with the data
//            totalBytesRead += numberOfBytesRead
//        }
        

        var elevationMatrix = [[Double]](count:1200, repeatedValue:[Double](count:1200, repeatedValue:0))

        
        let dataRange = NSRange(location: 0, length: 2884802)//1200 * 1200)
        var handNumbers = [Int8](count: 2884802, repeatedValue: 0)
        data.getBytes(&handNumbers, range: dataRange)
        
        
        var row = 0
        var column = 0
        for (var cell = 1; cell < 2884802; cell+=2) {
            elevationMatrix[row][column] = Double(handNumbers[cell])
            
            column++
            
            if column >= 1200 {
                column = 0
                row++
            }
            
            if row >= 1200 {
                break
            }
        }
        
        return elevationMatrix
    }
    
    
    func generateRandomData(count:Int) -> NSData
    {
        var array = Array<UInt8>(count: count, repeatedValue: 0)
        
        arc4random_buf(&array, count)
        return NSData(bytes: array, length: count)
    }
    
    
//    func convertDoubleToPixel(toConvert: [[Double]]) -> [[PixelData]] {
//        var returnImage:[[PixelData]] = [[]]
//        
//        for (var row = 0; row < toConvert.count; row++) {
//            
//            for (var column = 0; column < 1200; column++) {
//                
//                
//            }
//            
//        }
//        
//        return returnImage
//    }
    
    
    func researchForImageOverlay() {

        let red = PixelData(a: 100, r: 255, g: 0, b: 0)
        let green = PixelData(a: 100, r: 0, g: 255, b: 0)
        let blue = PixelData(a: 100, r: 0, g: 0, b: 255)
        
        
        let width = 30
        let height = 10
        var pixels=[PixelData]()
        //var pixels:[[PixelData]] = Array(count: height, repeatedValue: Array(count: width, repeatedValue: green))
        

        
//        for i in 0...299 {
//            for j in 0...299 {
//                pixels[i][j] = red
//            }
//        }
        for i in 1...100 {
            if (i%2 == 0) {
                pixels.append(green)
            } else {
                pixels.append(blue)
            }
        }
        
        let image = imageFromArgb32Bitmap(pixels, width: width, height: height)
        
//        var data = pixels // Copy to mutable []
//        let length = data.count * data.count * sizeof(PixelData) //data.count * sizeof(PixelData)
//        let theData = NSData(bytes: &data, length: length)
//        let image = getUIImageForRGBAData(width, height: height, data: theData)!
        
        
        
        
        
        
        var pixels2=[PixelData]()
        for i in 1...100 {
            pixels2.append(PixelData(a: 100, r: UInt8(i/2), g: 0, b: 0))
        }
        let image2 = imageFromArgb32Bitmap(pixels2, width: width, height: height)
        
        let image3 = mergeTwoImages(image, image2: image2, currentHeight: 5)
        
        
//        let image3 = image
        
        
        imageView.image = image3
        
        addOverlay(image3)
        
    }
    
    
    
    func imageFromArgb32Bitmap(pixels:[PixelData], width: Int, height: Int)-> UIImage {
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo:CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedFirst.rawValue)
        let bitsPerComponent:Int = 8
        let bitsPerPixel:Int = 32
        let bytesPerRow = width * Int(sizeof(PixelData))
        
        // assert(pixels.count == Int(width * height))
        
        var data = pixels // Copy to mutable []
        let length = data.count * sizeof(PixelData) //data.count * sizeof(PixelData)
        let providerRef = CGDataProviderCreateWithCFData(NSData(bytes: &data, length: length))
        
        let cgim = CGImageCreate(
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
        return UIImage(CGImage: cgim!)
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
    
    
    func addOverlay(image: UIImage) {
        
        var overlayTopLeftCoordinate: CLLocationCoordinate2D  = CLLocationCoordinate2D(latitude: 38.0, longitude: -77.0)
        var overlayTopRightCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 38.0, longitude: -76.5)
        var overlayBottomLeftCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.5, longitude: -77.0)

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
        
        
        
        let imageLocation = CLLocationCoordinate2D(latitude: 38.0, longitude: -77.0)
        let imageMapRect = overlayBoundingMapRect
        
        let overlay = ViewshedOverlay(midCoordinate: imageLocation, overlayBoundingMapRect: imageMapRect, viewshedImage: image)
        mapView.addOverlay(overlay)
    }
    
    

 
    
    
    
//    func getUIImageForRGBAData(width: Int, height: Int, data: NSData) -> UIImage? {
//        let pixelData = data.bytes
//        let bytesPerPixel:UInt = 4
//        let scanWidth = bytesPerPixel * UInt(width)
//        
//        let provider = CGDataProviderCreateWithData(nil, pixelData, Int(height) * Int(scanWidth), nil)
//        
//        let colorSpaceRef = CGColorSpaceCreateDeviceRGB()
//        let bitmapInfo:CGBitmapInfo = [.ByteOrderDefault, CGBitmapInfo(rawValue: CGImageAlphaInfo.Last.rawValue)];
//        let renderingIntent = CGColorRenderingIntent.RenderingIntentDefault;
//        
//        let imageRef = CGImageCreate(Int(width), Int(height), 8, Int(bytesPerPixel) * 8, Int(scanWidth), colorSpaceRef,
//            bitmapInfo, provider, nil, false, renderingIntent);
//        
//        return UIImage(CGImage: imageRef!)
//    }
    
    
    
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
    
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius * 2.0, regionRadius * 2.0)
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
    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
