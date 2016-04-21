import Foundation
import MapKit
import UIKit
import FogMachine

class ViewshedPalette: NSObject {
    
    private var observerHgtGrid: HgtGrid!
    lazy var viewshedResults = [[Int]]()
    var viewshedImage: UIImage!

    
    func setupNewPalette(observer: Observer) {
        let requiredHgtFiles = getRequiredHgtFiles(observer)

        observerHgtGrid = HgtGrid(hgtFiles: requiredHgtFiles)
        observer.updateXYLocationForGrid(observerHgtGrid)
    }
    
    // Determines if the required HGT files are available for a viewshed calculation
    func isViewshedPossible(observer: Observer) -> Bool {
        var isPossible = false
        let requiredHgtFiles: [Hgt] = getRequiredHgtFiles(observer)
        
        var count = 0
        for hgtFile in requiredHgtFiles {
            if hgtFile.hasHgtFileInDocuments() {
                count += 1
            }
        }
        
        // The number of required HGT files are found and at least one file is required
        if count == requiredHgtFiles.count && requiredHgtFiles.count > 0 {
            isPossible = true
        }
        
        return isPossible
    }
    
    
    func getRequiredHgtFiles(observer: Observer) -> [Hgt] {
        
        let box = AxisOrientedBoundingBox.getBoundingBox(observer.getObserverLocation(), radius: Double(observer.getRadius()))
        return getHgtNeededForBox(box)
    }
    
    
    func getHgtNeededForBox(box: AxisOrientedBoundingBox) -> [Hgt] {
        var hgts = [Hgt]()
        
        //get unique hgt for each of the corners
        for corner in box.getOrderedCorners() {
            let temptHgt = Hgt(coordinate: corner)
            hgts.append(temptHgt)
        }
        
        hgts = getUniqueCorners(hgts)
        
        return hgts
    }

    
    func getUniqueCorners(corner: [Hgt]) -> [Hgt] {
        var uniqueCorners = [Hgt]()
        let upperLeft = corner[0]
        let upperRight = corner[1]
        let lowerLeft = corner[2]
        let lowerRight = corner[3]
        
        
        if isCornerEqual(upperLeft, second: upperRight) && isCornerEqual(upperLeft, second: lowerLeft) && isCornerEqual(upperLeft, second: lowerRight) {
            // each corner identical
            uniqueCorners = [upperLeft]
        } else if isCornerEqual(upperLeft, second: upperRight) && isCornerEqual(lowerLeft, second: lowerRight) {
            // 2x1
            uniqueCorners = [upperLeft, lowerLeft]
        } else if isCornerEqual(upperLeft, second: lowerLeft) && isCornerEqual(upperRight, second: lowerRight) {
            // 1x2
            uniqueCorners = [upperLeft, upperRight]
        } else {
            //each corner unique
            uniqueCorners = [upperLeft, upperRight, lowerLeft, lowerRight]
        }
        
        return uniqueCorners
    }
    
    
    private func isCornerEqual(first: Hgt, second: Hgt) -> Bool {
        var isEqual = false
        if first.getCoordinate().latitude == second.getCoordinate().latitude && first.getCoordinate().longitude == second.getCoordinate().longitude {
            isEqual = true
        }
        return isEqual
    }
    
    
    func getHgtElevation() -> [[Int]] {
        return self.observerHgtGrid.getElevation()
    }
    
    
    func generateOverlay(image: UIImage) -> ViewshedOverlay {
        
        let imageLocation = observerHgtGrid.getHgtMidCoordinate()
        let imageMapRect = observerHgtGrid.getBoundingMapRect()
        
        let overlay = ViewshedOverlay(midCoordinate: imageLocation, overlayBoundingMapRect: imageMapRect, viewshedImage: image)
        
        return overlay
    }

    
    func getViewshedOverlay() -> ViewshedOverlay {
        self.viewshedImage = generateViewshedImage(self.viewshedResults)
        return generateOverlay(viewshedImage)
    }
    
    
    func generateViewshedImage(viewshed: [[Int]]) -> UIImage {
        
        // Flip width and height for 1x2 and 2x1 cases because CoreGraphics expects rows.
        var width = viewshed.count
        var height = viewshed[0].count
        var data: [Pixel] = []
        
        // CoreGraphics expects pixel data as rows, not columns.
        for y in 0 ..< width {
            for x in 0 ..< height {
                
                let cell = viewshed[y][x]
                if(cell == 0) {
                    data.append(Pixel(alpha: 0, red: 0, green: 0, blue: 0))
                } else if (cell == -1){
                    data.append(Pixel(alpha: 75, red: 126, green: 0, blue: 126))
                } else {
                    data.append(Pixel(alpha: 50, red: 0, green: 255, blue: 0))
                }
            }
        }
        
        // Actual width and height
        width = viewshed[0].count
        height = viewshed.count
        
        let image = imageFromArgb32Bitmap(data, width: width, height: height)
        
        return image
        
    }
    
    
//    func generateViewshedImageRedux(elevationGrid: [[Int]]) -> UIImage {
//        
//        let width = elevationGrid[0].count
//        let height = elevationGrid.count
//        
//        // how tall everest is?  not more than 9000 meters, right?
//        let maxBound = 9000
//        // the elevation of death valley???  prob not less than 100 meters below sea level
//        let minBound = -100
//        
//        
//        var maxElevation = minBound
//        // high stuff is red
//        let maxElevationColor = Pixel(alpha:50, red: 255, green: 0, blue: 0)
//        
//
//        var minElevation = maxBound
//        // low stuff is green
//        let minElevationColor = Pixel(alpha:50, red: 0, green: 255, blue: 0)
//
//        // find min and max for this grid
//        for(var y = 0; y < elevationGrid[0].count; y++) {
//            for(var x = 0; x < elevationGrid.count; x++) {
//                let elevation_at_xy = elevationGrid[y][x]
//                if(elevation_at_xy > maxElevation) {
//                    maxElevation = elevation_at_xy
//                }
//                if(elevation_at_xy < minElevation) {
//                    minElevation = elevation_at_xy
//                }
//            }
//        }
//        // bound them, if ouside range
//        maxElevation = min(maxBound, maxElevation)
//        minElevation = max(minBound, minElevation)
//        
//        
//        var elevationImage: [Pixel] = []
//        
//        // loop over the elevation data
//        for(var y = 0; y < elevationGrid[0].count; y++) {
//            for(var x = 0; x < elevationGrid.count; x++) {
//                
//                // elevation at y,x
//                // this is a number between minElevation and maxElevation
//                let elevation_at_xy = max(min(elevationGrid[y][x], maxElevation), minElevation)
//                
//                let percent_elevation_at_xy = Double(elevation_at_xy - minElevation) / Double(maxElevation - minElevation)
//                
//                // find color between green and red based on percentage
//                let colorR = UInt8((percent_elevation_at_xy * Double(maxElevationColor.red)) + ((1.0 - percent_elevation_at_xy) * Double(minElevationColor.red)))
//                let colorG = UInt8((percent_elevation_at_xy * Double(maxElevationColor.green)) + ((1.0 - percent_elevation_at_xy) * Double(minElevationColor.green)))
//                let colorB = UInt8((percent_elevation_at_xy * Double(maxElevationColor.blue)) + ((1.0 - percent_elevation_at_xy) * Double(minElevationColor.blue)))
//                
//                // color encoding elevation
//                let color = Pixel(alpha:100, red: colorR, green: colorG, blue: colorB)
//                
//                // projection for UIimage.  these are indexs in an array.  Do you floor or ceil them????
//                //var xprime = lon2x_SphericalMercator(x)
//                //var yprime = lat2y_SphericalMercator(y)
//                
//                // maybe this isn't an array anymore?!?  Not sure what utils apple provides for drawing...
//                elevationImage.append(color)
//            }
//        }
//        return imageFromArgb32Bitmap(elevationImage, width: width, height: height)
//    }
    
    
    func mergeViewshedResults(viewshedOne: [[Int]], viewshedTwo: [[Int]]) -> [[Int]] {
        var viewshedResult = viewshedOne
        
        for row in 0 ..< viewshedOne.count {
            for column in 0 ..< viewshedOne[row].count {
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