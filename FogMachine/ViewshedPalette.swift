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
    
    private var observerHgtGrid: HgtGrid!
    lazy var viewshedResults = [[Int]]()
    var viewshedImage: UIImage!

    
    func setupNewPalette(observer: Observer) {
        if checkForHgtFile(observer.coordinate) {
            if checkObserverCoordsInOneHgt(observer) {
                observerHgtGrid = generateHgtGrid(observer)
            } else {
                observerHgtGrid = generateKnownHgtGrid(observer)
            }
        }
    }
    
    // Will generate a 1x1 or 2x2 HgtGrid based on the location and size of the Observer
    func generateHgtGrid(observer: Observer) -> HgtGrid {

        var observerPosition: GridPosition = GridPosition.UpperLeft
        let observersHgtCoordinate = observer.getObserversHgtCoordinate()
        let observerHgt = getHgtFile(observersHgtCoordinate.latitude, longitude: observersHgtCoordinate.longitude)
        
        let hgtGrid = HgtGrid(singleHgt: observerHgt)
        
        if !checkRadiusInOneHgt(observer) {
            
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
                upperLeftHgt = observerHgt
                lowerLeftHgt = getHgtFile(observerHgt.coordinate.latitude - 1, longitude: observerHgt.coordinate.longitude)
                upperRightHgt = getHgtFile(observerHgt.coordinate.latitude, longitude: observerHgt.coordinate.longitude + 1)
                lowerRightHgt = getHgtFile(observerHgt.coordinate.latitude - 1, longitude: observerHgt.coordinate.longitude + 1)
                observerPosition = GridPosition.UpperLeft
            } else if right && top {
                upperLeftHgt = getHgtFile(observerHgt.coordinate.latitude - 1, longitude: observerHgt.coordinate.longitude)
                lowerLeftHgt = observerHgt
                upperRightHgt = getHgtFile(observerHgt.coordinate.latitude - 1, longitude: observerHgt.coordinate.longitude + 1)
                lowerRightHgt = getHgtFile(observerHgt.coordinate.latitude, longitude: observerHgt.coordinate.longitude + 1)
                observerPosition = GridPosition.LowerLeft
            } else if left && bottom {
                upperLeftHgt = getHgtFile(observerHgt.coordinate.latitude, longitude: observerHgt.coordinate.longitude - 1)
                lowerLeftHgt = getHgtFile(observerHgt.coordinate.latitude - 1, longitude: observerHgt.coordinate.longitude - 1)
                upperRightHgt = observerHgt
                lowerRightHgt = getHgtFile(observerHgt.coordinate.latitude - 1, longitude: observerHgt.coordinate.longitude)
                observerPosition = GridPosition.UpperRight
            } else if left && top {
                upperLeftHgt = getHgtFile(observerHgt.coordinate.latitude + 1, longitude: observerHgt.coordinate.longitude - 1)
                lowerLeftHgt = getHgtFile(observerHgt.coordinate.latitude, longitude: observerHgt.coordinate.longitude - 1)
                upperRightHgt = getHgtFile(observerHgt.coordinate.latitude + 1, longitude: observerHgt.coordinate.longitude)
                lowerRightHgt = observerHgt
                observerPosition = GridPosition.LowerRight
            } else {
                
                //only one side is an overlap, so force it to be a 2x2
                if top || bottom {
                    upperLeftHgt = getHgtFile(observerHgt.coordinate.latitude, longitude: observerHgt.coordinate.longitude - 1)
                    lowerLeftHgt = getHgtFile(observerHgt.coordinate.latitude - 1, longitude: observerHgt.coordinate.longitude - 1)
                    upperRightHgt = observerHgt
                    lowerRightHgt = getHgtFile(observerHgt.coordinate.latitude - 1, longitude: observerHgt.coordinate.longitude)
                    observerPosition = GridPosition.UpperRight
                    printOut("THIS IS A HACK forcing to upperRight")
                    
                } else if left || right {
                    upperLeftHgt = getHgtFile(observerHgt.coordinate.latitude, longitude: observerHgt.coordinate.longitude - 1)
                    lowerLeftHgt = getHgtFile(observerHgt.coordinate.latitude - 1, longitude: observerHgt.coordinate.longitude - 1)
                    upperRightHgt = observerHgt
                    lowerRightHgt = getHgtFile(observerHgt.coordinate.latitude - 1, longitude: observerHgt.coordinate.longitude)
                    observerPosition = GridPosition.UpperRight
                    printOut("THIS IS A HACK force upperRight")
                    
                }
                
            }
            
            hgtGrid.configureGrid(upperLeftHgt, lowerLeftHgt: lowerLeftHgt, upperRightHgt: upperRightHgt, lowerRightHgt: lowerRightHgt, observerPosition: observerPosition)
            
            if observer.xCoord <= Srtm3.MAX_SIZE && observer.yCoord <= Srtm3.MAX_SIZE {
                // Adjust Observer grid's xCoord and yCoord for HgtGrid
                observer.updateXYLocationForGrid(hgtGrid)
            }
        }
        
        return hgtGrid
    }
    
    // Will generate a 2x2 HgtGrid for Observer with a known 2x2 size
    func generateKnownHgtGrid(observer: Observer) -> HgtGrid {
        
        var observerPosition: GridPosition = GridPosition.UpperLeft
        let observersHgtCoordinate = observer.getObserversHgtCoordinate()
        let observerHgt = getHgtFile(observersHgtCoordinate.latitude, longitude: observersHgtCoordinate.longitude)
        
        let hgtGrid = HgtGrid(singleHgt: observerHgt)
        
        var upperLeftHgt: Hgt!
        var lowerLeftHgt: Hgt!
        var upperRightHgt: Hgt!
        var lowerRightHgt: Hgt!
        
        //Determine where the xCoord and yCoord are in a 2x2 grid
        // xCoord and yCoord are oriented oddly ([x,y] 0,0 is top left and 1200,1 is lower left), so the overlaps's are awkward
        var isInsideYRegion = false
        var isInsideXRegion = false
        
        if observer.yCoord < Srtm3.MAX_SIZE {
            isInsideYRegion = true
        }
        
        if observer.xCoord < Srtm3.MAX_SIZE {
            isInsideXRegion = true
        }
        
        if isInsideYRegion && isInsideXRegion {
            upperLeftHgt = observerHgt
            lowerLeftHgt = getHgtFile(observerHgt.coordinate.latitude - 1, longitude: observerHgt.coordinate.longitude)
            upperRightHgt = getHgtFile(observerHgt.coordinate.latitude, longitude: observerHgt.coordinate.longitude + 1)
            lowerRightHgt = getHgtFile(observerHgt.coordinate.latitude - 1, longitude: observerHgt.coordinate.longitude + 1)
            observerPosition = GridPosition.UpperLeft
        } else if isInsideYRegion && !isInsideXRegion {
            upperLeftHgt = getHgtFile(observerHgt.coordinate.latitude - 1, longitude: observerHgt.coordinate.longitude)
            lowerLeftHgt = observerHgt
            upperRightHgt = getHgtFile(observerHgt.coordinate.latitude - 1, longitude: observerHgt.coordinate.longitude + 1)
            lowerRightHgt = getHgtFile(observerHgt.coordinate.latitude, longitude: observerHgt.coordinate.longitude + 1)
            observerPosition = GridPosition.LowerLeft
        } else if !isInsideYRegion && isInsideXRegion {
            upperLeftHgt = getHgtFile(observerHgt.coordinate.latitude, longitude: observerHgt.coordinate.longitude - 1)
            lowerLeftHgt = getHgtFile(observerHgt.coordinate.latitude - 1, longitude: observerHgt.coordinate.longitude - 1)
            upperRightHgt = observerHgt
            lowerRightHgt = getHgtFile(observerHgt.coordinate.latitude - 1, longitude: observerHgt.coordinate.longitude)
            observerPosition = GridPosition.UpperRight
        } else if !isInsideYRegion && !isInsideXRegion {
            upperLeftHgt = getHgtFile(observerHgt.coordinate.latitude + 1, longitude: observerHgt.coordinate.longitude - 1)
            lowerLeftHgt = getHgtFile(observerHgt.coordinate.latitude, longitude: observerHgt.coordinate.longitude - 1)
            upperRightHgt = getHgtFile(observerHgt.coordinate.latitude + 1, longitude: observerHgt.coordinate.longitude)
            lowerRightHgt = observerHgt
            observerPosition = GridPosition.LowerRight
        }
        
        hgtGrid.configureGrid(upperLeftHgt, lowerLeftHgt: lowerLeftHgt, upperRightHgt: upperRightHgt, lowerRightHgt: lowerRightHgt, observerPosition: observerPosition)
        
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
                    //printOut("\(file) (Lat:\(hgtCoordinate.latitude) Lon:\(hgtCoordinate.longitude))")
                    break
                }
            }
        } catch let error as NSError {
            printOut("Error getting HGT file " + " \(error): \(error.userInfo)")
        }
        
        return foundHgt
    }
    
    
    func checkObserverCoordsInOneHgt(observer: Observer) -> Bool {
        var isWithinOneHgt = true
        
        if observer.xCoord > Srtm3.MAX_SIZE || observer.yCoord > Srtm3.MAX_SIZE {
            isWithinOneHgt = false
        }
        
        return isWithinOneHgt
    }
    
    
    func checkRadiusInOneHgt(observer: Observer) -> Bool {
        var isRadiusWithinHgt = true
        //Determine which side radius is past the currHgt file
        // xCoord and yCoord are oriented oddly ([x,y] 0,0 is top left and 1200,1 is lower left), so the overlaps's are awkward
        let topOverlap = observer.xCoord - observer.radius
        let leftOverlap = observer.yCoord - observer.radius
        let bottomOverlap = observer.xCoord + observer.radius
        let rightOverlap = observer.yCoord + observer.radius
        
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
                if isCoordinateInHgt(checkCoordinate, hgtCoordinate: hgtCoordinate) {
                    haveHgtForCoordinate = true
                    //printOut("\(file) (Lat:\(hgtCoordinate.latitude) Lon:\(hgtCoordinate.longitude))")
                    break
                }
            }
        } catch let error as NSError {
            printOut("Error checking HGT files " + " \(error): \(error.userInfo)")
        }
        
        return haveHgtForCoordinate
    }
    
    //Add to HGT.swift
    func isCoordinateInHgt(checkCoordinate: CLLocationCoordinate2D, hgtCoordinate: CLLocationCoordinate2D) -> Bool {
        var inHgt = false
        
        if checkCoordinate.latitude < hgtCoordinate.latitude + 1 &&
            checkCoordinate.latitude > hgtCoordinate.latitude &&
            checkCoordinate.longitude > hgtCoordinate.longitude &&
            checkCoordinate.longitude < hgtCoordinate.longitude + 1 {
                inHgt = true
        }
        
        return inHgt
    }
    
    
    func getElevation() -> [[Int]] {
        return self.observerHgtGrid.getElevation()
    }
    
    
    func addOverlay(image: UIImage) -> ViewshedOverlay {
        
        let imageLocation = observerHgtGrid.getHgtCoordinate()
        let hgtGridSize = observerHgtGrid.getHgtGridSize()
        
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

    
    func getViewshedOverlay() -> ViewshedOverlay {
        self.viewshedImage = generateViewshedImage(self.viewshedResults)
        return addOverlay(viewshedImage)
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

    
    func printOut(output: String) {
        dispatch_async(dispatch_get_main_queue()) {
            print(output)
        }
    }

}