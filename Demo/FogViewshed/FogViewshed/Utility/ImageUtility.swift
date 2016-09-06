import Foundation
import MapKit
import UIKit
import FogMachine

class ImageUtility: NSObject {

    static func generateElevationOverlay(elevationDataGrid: DataGrid) -> GridOverlay {
        return GridOverlay(midCoordinate: elevationDataGrid.boundingBoxAreaExtent.getCentroid(), overlayBoundingMapRect: elevationDataGrid.boundingBoxAreaExtent.asMKMapRect(), viewshedImage: elevationToUIImage(elevationDataGrid.data))
    }
    
    static func generateViewshedOverlay(viewshedDataGrid: DataGrid) -> GridOverlay {
        return GridOverlay(midCoordinate: viewshedDataGrid.boundingBoxAreaExtent.getCentroid(), overlayBoundingMapRect: viewshedDataGrid.boundingBoxAreaExtent.asMKMapRect(), viewshedImage: viewshedToUIImage(viewshedDataGrid.data))
    }

    static func elevationToUIImage(elevationGrid: [[Int]]) -> UIImage {

        let height = elevationGrid.count
        let width = elevationGrid[0].count

        var maxElevation = Elevation.MIN_BOUND
        // high stuff is red
        let maxElevationColor = Pixel(alpha:50, red: 255, green: 0, blue: 0)

        var minElevation = Elevation.MAX_BOUND
        // low stuff is green
        let minElevationColor = Pixel(alpha:50, red: 0, green: 255, blue: 0)

        // find min and max for this grid
        for x in 0 ..< height {
            for y in 0 ..< width {
                let elevation_at_xy = elevationGrid[x][y]
                if(elevation_at_xy == Srtm.DATA_VOID || elevation_at_xy == Srtm.NO_DATA) {
                    continue
                }
                
                if(elevation_at_xy > maxElevation) {
                    maxElevation = elevation_at_xy
                }
                if(elevation_at_xy < minElevation) {
                    minElevation = elevation_at_xy
                }
            }
        }
        // bound them, if outside range
        maxElevation = min(Elevation.MAX_BOUND, maxElevation)
        minElevation = max(Elevation.MIN_BOUND, minElevation)

        var elevationImage: [Pixel] = []

        // loop over the elevation data
        for x in 0 ..< height {
            for y in 0 ..< width {
                // elevation at x,y
                let elevation_at_xy = elevationGrid[(height - 1) - x][y]

                var p = Pixel(alpha: 0, red: 0, green: 0, blue: 0)
                if(elevation_at_xy == Srtm.DATA_VOID) {
                    p = Pixel(alpha: 0, red: 0, green: 0, blue: 0)
                } else if (elevation_at_xy == Srtm.NO_DATA) {
                    p = Pixel(alpha: 50, red: 0, green: 0, blue: 255)
                } else {
                    let elevationRange = max(Double(maxElevation - minElevation), 1.0)
                    // this is a percetage between minElevation and maxElevation
                    let percent_elevation_at_xy = Double(max(min(elevation_at_xy, maxElevation), minElevation) - minElevation) / elevationRange

                    // find color between green and red based on percentage
                    let colorR = UInt8((percent_elevation_at_xy * Double(maxElevationColor.red)) + ((1.0 - percent_elevation_at_xy) * Double(minElevationColor.red)))
                    let colorG = UInt8((percent_elevation_at_xy * Double(maxElevationColor.green)) + ((1.0 - percent_elevation_at_xy) * Double(minElevationColor.green)))
                    let colorB = UInt8((percent_elevation_at_xy * Double(maxElevationColor.blue)) + ((1.0 - percent_elevation_at_xy) * Double(minElevationColor.blue)))

                    // color encoding elevation
                    p = Pixel(alpha:100, red: colorR, green: colorG, blue: colorB)
                }

                elevationImage.append(p)
            }
        }
        return imageFromArgb32Bitmap(elevationImage, width: width, height: height)
    }
    
    static func viewshedToUIImage(viewshed: [[Int]]) -> UIImage {
        let height = viewshed.count
        let width = viewshed[0].count
        var data: [Pixel] = []
        
        for x in 0 ..< height {
            for y in 0 ..< width {
                let vxy:Int = viewshed[(height - 1) - x][y]
                var p:Pixel
                if(vxy == Viewshed.NOT_VISIBLE) {
                    p = Pixel(alpha: 50, red: 100, green: 0, blue: 0)
                } else if(vxy == Viewshed.VISIBLE) {
                    p = Pixel(alpha: 50, red: 0, green: 100, blue: 0)
                } else if(vxy == Viewshed.OBSERVER) {
                    p = Pixel(alpha: 50, red: 0, green: 0, blue: 0)
                } else if (vxy == Viewshed.NO_DATA){
                    p = Pixel(alpha: 0, red: 0, green: 0, blue: 0)
                } else {
                    p = Pixel(alpha: 50, red: 255, green: 255, blue: 0)
                }
                data.append(p);
            }
        }
        
        let image = imageFromArgb32Bitmap(data, width: width, height: height)
        return image
    }

    // TODO : see if this can be sped up
    private static func imageFromArgb32Bitmap(pixels:[Pixel], width: Int, height: Int)-> UIImage {

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
