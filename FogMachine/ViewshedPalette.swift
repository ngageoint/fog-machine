//
//  ViewshedPalette.swift
//  FogMachine
//
//  Created by Chris Wasko on 1/31/16.
//  Copyright © 2016 NGA. All rights reserved.
//

import Foundation
import MapKit
import UIKit


class ViewshedPalette: NSObject {
    
    var observerHgt: Hgt!
    lazy var viewshedResults = [[Int]]()
    var viewshedImage: UIImage!
    
    
    func testForMultiHgtFiles(observer: Observer, currHgt: Hgt) -> ViewshedOverlay {
        
        var viewshedOverlay: ViewshedOverlay!
        observer.radius = 750
        observer.elevation = 10
        
        // Detect where the pin was dropped
        // Check for HGT file
        if checkForHgtFile(observer.coordinate) {
            
            // Check radius specified
            if checkRadiusInOneHgt(observer) {
                // Do viewshed as normal
                let obsViewshed = Viewshed(elevation: currHgt.getElevation(), observer: observer)
                let obsResults:[[Int]] = obsViewshed.viewshed()
                //self.pinObserverLocation(observer)
                
                let image = self.generateViewshedImage(obsResults)
                viewshedOverlay = self.addOverlay(image, imageLocation: currHgt.getCoordinate())
                
            } else {
                // Check for additional HGT files if radius overlaps other HGT regions
                // Create HgtGrid if needed, otherwise use Hgt
                let hgtGrid = generateHgtGrid(observer, currentHgt: currHgt)
                
                // Adjust Observer xCoord and yCoord for HgtGrid
                observer.setHgtGridLocation(hgtGrid.upperLeftHgt.getCoordinate())
                
                
                // Do viewshed!
                let obsViewshed = ViewshedFog(elevation: hgtGrid.getElevation(), observer: observer, numberOfQuadrants: 1, whichQuadrant: 1)
                let obsResults:[[Int]] = obsViewshed.viewshedParallel(Srtm3.MAX_SIZE * 2)
                //self.pinObserverLocation(observer)
                
                let image = self.generateViewshedImage(obsResults)
                viewshedOverlay = self.addOverlay(image, imageLocation: hgtGrid.upperLeftHgt.getCoordinate(), hgtGridSize: 1.0)
                
                
            }
        }
        
        return viewshedOverlay
    }
    
    
    func singleTest() {
        let upperLeftHgt = Hgt(filename: "N39W076")
        let lowerLeftHgt = Hgt(filename:"N38W076")
        let upperRightHgt = Hgt(filename:"N39W075")
        let lowerRightHgt = Hgt(filename:"N38W075")
        let grid = HgtGrid(upperLeftHgt: upperLeftHgt, lowerLeftHgt: lowerLeftHgt, upperRightHgt: upperRightHgt, lowerRightHgt: lowerRightHgt, observersHgt: GridPosition.UpperLeft)
        
        let x = 1201//1371
        let y = 1201//1431
        let radius = 100//300
        
        
        let observer = Observer(name: "Cubed", xCoord: x, yCoord: y, elevation: 20, radius: radius, coordinate: CLLocationCoordinate2DMake(0,0))//39.8605328892589, -74.8089092422981))
        observer.generateCoordiantesFromXY(grid.upperLeftHgt.getCoordinate())
        
        let obsViewshed = Viewshed(elevation: grid.getElevation(), observer: observer)
        let obsResults:[[Int]] = obsViewshed.viewshed(Srtm3.MAX_SIZE * 2)
        //self.pinObserverLocation(observer)
        
        let image = self.generateViewshedImage(obsResults)
        self.addOverlay(image, imageLocation: grid.upperLeftHgt.getCoordinate(), hgtGridSize: 1.0)
    }
    
    
    func generateHgtGrid(observer: Observer, currentHgt: Hgt) -> HgtGrid {
        
        var observerHgt: GridPosition!
        var upperLeftHgt: Hgt!
        var lowerLeftHgt: Hgt!
        var upperRightHgt: Hgt!
        var lowerRightHgt: Hgt!
        
        //Determine which side radius is past the currHgt file
        // xCoord and yCoord are oriented oddly ([x,y] 0,0 is top left and 1200,1 is lower left), so the overlaps's are awkward
        let topOverlap = observer.xCoord - observer.radius
        let leftOverlap = observer.yCoord - observer.radius
        let bottomOverlap = observer.xCoord + observer.radius
        let rightOverlap = observer.yCoord + observer.radius
        
        var left = false
        var top = false
        var right = false
        var bottom = false
        
        if leftOverlap < 0 {
            left = true
        }
        
        if topOverlap < 0 {
            top = true
        }
        
        if rightOverlap > Srtm3.MAX_SIZE {
            right = true
        }
        
        if bottomOverlap > Srtm3.MAX_SIZE {
            bottom = true
        }
        
        if right && bottom {
            upperLeftHgt = currentHgt
            lowerLeftHgt = getHgtFile(currentHgt.coordinate.latitude - 1, longitude: currentHgt.coordinate.longitude)
            upperRightHgt = getHgtFile(currentHgt.coordinate.latitude, longitude: currentHgt.coordinate.longitude + 1)
            lowerRightHgt = getHgtFile(currentHgt.coordinate.latitude - 1, longitude: currentHgt.coordinate.longitude + 1)
            observerHgt = GridPosition.UpperLeft
        } else if right && top {
            upperLeftHgt = getHgtFile(currentHgt.coordinate.latitude - 1, longitude: currentHgt.coordinate.longitude)
            lowerLeftHgt = currentHgt
            upperRightHgt = getHgtFile(currentHgt.coordinate.latitude - 1, longitude: currentHgt.coordinate.longitude + 1)
            lowerRightHgt = getHgtFile(currentHgt.coordinate.latitude, longitude: currentHgt.coordinate.longitude + 1)
            observerHgt = GridPosition.LowerLeft
        } else if left && bottom {
            upperLeftHgt = getHgtFile(currentHgt.coordinate.latitude, longitude: currentHgt.coordinate.longitude - 1)
            lowerLeftHgt = getHgtFile(currentHgt.coordinate.latitude - 1, longitude: currentHgt.coordinate.longitude - 1)
            upperRightHgt = currentHgt
            lowerRightHgt = getHgtFile(currentHgt.coordinate.latitude - 1, longitude: currentHgt.coordinate.longitude)
            observerHgt = GridPosition.UpperRight
        } else if left && top {
            upperLeftHgt = getHgtFile(currentHgt.coordinate.latitude + 1, longitude: currentHgt.coordinate.longitude - 1)
            lowerLeftHgt = getHgtFile(currentHgt.coordinate.latitude, longitude: currentHgt.coordinate.longitude - 1)
            upperRightHgt = getHgtFile(currentHgt.coordinate.latitude + 1, longitude: currentHgt.coordinate.longitude)
            lowerRightHgt = currentHgt
            observerHgt = GridPosition.LowerRight
        } else {
            //only one side is an overlap, so force it to be a 2x2
            if top || bottom {
                upperLeftHgt = getHgtFile(currentHgt.coordinate.latitude, longitude: currentHgt.coordinate.longitude - 1)
                lowerLeftHgt = getHgtFile(currentHgt.coordinate.latitude - 1, longitude: currentHgt.coordinate.longitude - 1)
                upperRightHgt = currentHgt
                lowerRightHgt = getHgtFile(currentHgt.coordinate.latitude - 1, longitude: currentHgt.coordinate.longitude)
                observerHgt = GridPosition.UpperRight
                print("THIS IS A HACK forcing to upperRight")
                
            } else if left || right {
                upperLeftHgt = getHgtFile(currentHgt.coordinate.latitude, longitude: currentHgt.coordinate.longitude - 1)
                lowerLeftHgt = getHgtFile(currentHgt.coordinate.latitude - 1, longitude: currentHgt.coordinate.longitude - 1)
                upperRightHgt = currentHgt
                lowerRightHgt = getHgtFile(currentHgt.coordinate.latitude - 1, longitude: currentHgt.coordinate.longitude)
                observerHgt = GridPosition.UpperRight
                print("THIS IS A HACK force upperRight")
                
            }
            
        }
        
        print(observerHgt.rawValue)
        
        let hgtGrid = HgtGrid(upperLeftHgt: upperLeftHgt, lowerLeftHgt: lowerLeftHgt, upperRightHgt: upperRightHgt, lowerRightHgt: lowerRightHgt, observersHgt: observerHgt)
        
        return hgtGrid
    }
    
    
    func getHgtFile(latitude: Double, longitude: Double) -> Hgt {
        var foundHgt: Hgt!
        let neededCoordinate = CLLocationCoordinate2DMake(latitude, longitude)
        
        do {
            let folder = NSBundle.mainBundle().resourcePath! + "/HGT"
            let files = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(folder)
            for file: String in files {
                let name = file.componentsSeparatedByString(".")[0]
                let tempHgt = Hgt(filename: name)
                let hgtCoordinate = tempHgt.getCoordinate()
                if neededCoordinate.latitude == hgtCoordinate.latitude && neededCoordinate.longitude == hgtCoordinate.longitude {
                    foundHgt = tempHgt
                    print("\(file) (Lat:\(hgtCoordinate.latitude) Lon:\(hgtCoordinate.longitude))")
                    break
                }
            }
        } catch let error as NSError {
            print("Error getting HGT file " + " \(error): \(error.userInfo)")
        }
        
        return foundHgt
    }
    
    
    func checkRadiusInOneHgt(observer: Observer) -> Bool {
        var isRadiusWithinHgt = true
        let leftOverlap = observer.xCoord - observer.radius
        let topOverlap = observer.yCoord - observer.radius
        let rightOverlap = observer.xCoord + observer.radius
        let bottomOverlap = observer.yCoord + observer.radius
        
        if leftOverlap < 0 ||
            topOverlap < 0 ||
            rightOverlap > Srtm3.MAX_SIZE ||
            bottomOverlap > Srtm3.MAX_SIZE {
                isRadiusWithinHgt = false
        }
        
        return isRadiusWithinHgt
    }
    
    
    // Add to HGT.swift
    func checkForHgtFile(checkCoordinate: CLLocationCoordinate2D) -> Bool {
        var haveHgtForCoordinate = false
        
        do {
            let folder = NSBundle.mainBundle().resourcePath! + "/HGT"
            let files = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(folder)
            for file: String in files {
                let name = file.componentsSeparatedByString(".")[0]
                let tempHgt = Hgt(filename: name)
                let hgtCoordinate = tempHgt.getCoordinate()
                if coordinateInHgt(checkCoordinate, hgtCoordinate: hgtCoordinate) {
                    haveHgtForCoordinate = true
                    print("\(file) (Lat:\(hgtCoordinate.latitude) Lon:\(hgtCoordinate.longitude))")
                    break
                }
            }
        } catch let error as NSError {
            print("Error checking HGT files " + " \(error): \(error.userInfo)")
        }
        
        return haveHgtForCoordinate
    }
    
    //Add to HGT.swift
    func coordinateInHgt(checkCoordinate: CLLocationCoordinate2D, hgtCoordinate: CLLocationCoordinate2D) -> Bool {
        var inHgt = false
        
        if checkCoordinate.latitude < hgtCoordinate.latitude + 1 &&
            checkCoordinate.latitude > hgtCoordinate.latitude &&
            checkCoordinate.longitude > hgtCoordinate.longitude &&
            checkCoordinate.longitude < hgtCoordinate.longitude + 1 {
                inHgt = true
        }
        
        return inHgt
    }
    
    //Make HGT file lazy load elevation and use it's parseCoordinate
//    func parseCoordinate(filename: String) -> CLLocationCoordinate2D {
//        
//        let northSouth = filename.substringWithRange(Range<String.Index>(start: filename.startIndex,end: filename.startIndex.advancedBy(1)))
//        let latitudeValue = filename.substringWithRange(Range<String.Index>(start: filename.startIndex.advancedBy(1),end: filename.startIndex.advancedBy(3)))
//        let westEast = filename.substringWithRange(Range<String.Index>(start: filename.startIndex.advancedBy(3),end: filename.startIndex.advancedBy(4)))
//        let longitudeValue = filename.substringWithRange(Range<String.Index>(start: filename.startIndex.advancedBy(4),end: filename.endIndex))
//        
//        var latitude:Double = Double(latitudeValue)!
//        var longitude:Double = Double(longitudeValue)!
//        
//        if (northSouth.uppercaseString == "S") {
//            latitude = latitude * -1.0
//        }
//        
//        if (westEast.uppercaseString == "W") {
//            longitude = longitude * -1.0
//        }
//        
//        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
//    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    func addOverlay(image: UIImage, imageLocation: CLLocationCoordinate2D, hgtGridSize: Double = 0.0) -> ViewshedOverlay {
        
        var overlayTopLeftCoordinate: CLLocationCoordinate2D  = CLLocationCoordinate2D(
            latitude: imageLocation.latitude + 1.0,
            longitude: imageLocation.longitude)
        var overlayTopRightCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(
            latitude: imageLocation.latitude + 1.0,
            longitude: imageLocation.longitude + 1.0 + hgtGridSize)
        var overlayBottomLeftCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(
            latitude: imageLocation.latitude - hgtGridSize,
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
        
        return overlay
        
//        dispatch_async(dispatch_get_main_queue()) {
//            self.mapView.addOverlay(overlay)
//        }
    }

    
    func viewshedOverlay(hgtGridSize: Double = 0.0) -> ViewshedOverlay {
        self.viewshedImage = generateViewshedImage(self.viewshedResults)
        return addOverlay(viewshedImage, imageLocation: self.observerHgt.getCoordinate(), hgtGridSize: hgtGridSize)
    }
    
    
    func generateViewshedImage(viewshed: [[Int]]) -> UIImage {
        
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

    
    

}