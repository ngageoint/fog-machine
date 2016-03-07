//
//  HgtGrid
//  FogMachine
//
//  Created by Chris Wasko on 1/29/16.
//  Copyright © 2016 NGA. All rights reserved.
//

import Foundation
import MapKit

class HgtGrid: NSObject {
    // Supports generating 1x1, 2x2, 2x1, or 1x2 grid
    
    var elevation: [[Int]]!
    var hgtFiles: [Hgt]!
    
    
    init(hgtFiles: [Hgt]) {
        super.init()
        self.hgtFiles = hgtFiles
        self.elevation = generateElevation()
    }
    
    
    func getElevation() -> [[Int]] {
        return elevation
    }
    
    // Supports generating 1x1, 2x2, 2x1, or 1x2 elevation
    private func generateElevation() -> [[Int]] {
        
        var newElevation = [[Int]]()
        var row = 0
        var column = 0
        let numCells = Srtm3.MAX_SIZE * Srtm3.MAX_SIZE * hgtFiles.count
        
        if hgtFiles.count == 4 {
            newElevation = [[Int]](count:Srtm3.MAX_SIZE * 2, repeatedValue:[Int](count:Srtm3.MAX_SIZE * 2, repeatedValue:0))
            
            for (var cell = 0; cell < numCells; cell+=1) {
                
                if column < Srtm3.MAX_SIZE && row < Srtm3.MAX_SIZE {
                    newElevation[row][column] = hgtFiles[0].elevation[row][column]
                    
                } else if column < Srtm3.MAX_SIZE && row >= Srtm3.MAX_SIZE {
                    newElevation[row][column] = hgtFiles[2].elevation[row - Srtm3.MAX_SIZE][column]
                    
                } else if column >= Srtm3.MAX_SIZE && row < Srtm3.MAX_SIZE {
                    newElevation[row][column] = hgtFiles[1].elevation[row][column - Srtm3.MAX_SIZE]
                    
                } else if column >= Srtm3.MAX_SIZE && row >= Srtm3.MAX_SIZE {
                    newElevation[row][column] = hgtFiles[3].elevation[row - Srtm3.MAX_SIZE][column - Srtm3.MAX_SIZE]
                }
                
                column++
                
                if column >= Srtm3.MAX_SIZE * 2 {
                    column = 0
                    row++
                }
                
                if row >= Srtm3.MAX_SIZE * 2 {
                    break
                }
            }
            
        } else if hgtFiles.count == 2 {
            
            if hgtFiles[0].coordinate.latitude == hgtFiles[1].coordinate.latitude {
                // 1x2
                newElevation = [[Int]](count:Srtm3.MAX_SIZE, repeatedValue:[Int](count:Srtm3.MAX_SIZE * 2, repeatedValue:0))
                
                for (var cell = 0; cell < numCells; cell+=1) {
                    
                    if column < Srtm3.MAX_SIZE && row < Srtm3.MAX_SIZE {
                        newElevation[row][column] = hgtFiles[0].elevation[row][column]
                        
                    } else if column >= Srtm3.MAX_SIZE && row < Srtm3.MAX_SIZE {
                        newElevation[row][column] = hgtFiles[1].elevation[row][column - Srtm3.MAX_SIZE]
                    }
                    
                    column++
                    
                    if column >= Srtm3.MAX_SIZE * 2 {
                        column = 0
                        row++
                    }
                    
                    if row >= Srtm3.MAX_SIZE {
                        break
                    }
                }
                
            } else if hgtFiles[0].coordinate.longitude == hgtFiles[1].coordinate.longitude {
                // 2x1
                newElevation = [[Int]](count:Srtm3.MAX_SIZE * 2, repeatedValue:[Int](count:Srtm3.MAX_SIZE, repeatedValue:0))
                
                for (var cell = 0; cell < numCells; cell+=1) {
                    
                    if column < Srtm3.MAX_SIZE && row < Srtm3.MAX_SIZE {
                        newElevation[row][column] = hgtFiles[0].elevation[row][column]
                        
                    } else if column < Srtm3.MAX_SIZE && row >= Srtm3.MAX_SIZE {
                        newElevation[row][column] = hgtFiles[1].elevation[row - Srtm3.MAX_SIZE][column]
                    }
                    
                    column++
                    
                    if column >= Srtm3.MAX_SIZE {
                        column = 0
                        row++
                    }
                    
                    if row >= Srtm3.MAX_SIZE * 2 {
                        break
                    }
                }
            }
            
        } else if hgtFiles.count == 1 {
            newElevation = hgtFiles[0].elevation
        }
        
        return newElevation
    }
    
    
    func getHgtMidCoordinate() -> CLLocationCoordinate2D {
        var calculatedCoordinate = hgtFiles[0].getCoordinate()
        
        if hgtFiles.count == 4 {
            calculatedCoordinate = hgtFiles[1].getCoordinate()
        } else if hgtFiles.count == 2 {
            
            if hgtFiles[0].coordinate.latitude == hgtFiles[1].coordinate.latitude {
                // 1x2
                calculatedCoordinate = hgtFiles[1].getCoordinate()
                
            } else if hgtFiles[0].coordinate.longitude == hgtFiles[1].coordinate.longitude {
                // 2x1
                calculatedCoordinate = hgtFiles[0].getCoordinate()
            }
        }
        
        return calculatedCoordinate
    }
    
    // Used to update the Observer x/y coordinate based on the size of the grid
    func getUpperLeftHgtCoordinate() -> CLLocationCoordinate2D {
        return hgtFiles[0].getCoordinate()
    }
    
    
    func getBoundingMapRect() -> MKMapRect {
        
        let imageLocation = hgtFiles[0].getCoordinate()
        
        var overlayTopLeftCoordinate  = CLLocationCoordinate2D(
            latitude: imageLocation.latitude + 1.0,
            longitude: imageLocation.longitude)
        
        var overlayTopRightCoordinate = CLLocationCoordinate2D(
            latitude: imageLocation.latitude + 1.0,
            longitude: imageLocation.longitude + 1.0)
        
        var overlayBottomLeftCoordinate = CLLocationCoordinate2D(
            latitude: imageLocation.latitude,
            longitude: imageLocation.longitude)
        
        if hgtFiles.count == 4 {
            // 2x2
            overlayTopRightCoordinate = CLLocationCoordinate2D(
                latitude: hgtFiles[1].getCoordinate().latitude + 1.0,
                longitude: hgtFiles[1].getCoordinate().longitude + 1.0)
            overlayBottomLeftCoordinate = CLLocationCoordinate2D(
                latitude: hgtFiles[2].getCoordinate().latitude,
                longitude: hgtFiles[2].getCoordinate().longitude)
        } else if hgtFiles.count == 2 {
            
            if hgtFiles[0].coordinate.latitude == hgtFiles[1].coordinate.latitude {
                // 1x2
                overlayTopRightCoordinate = CLLocationCoordinate2D(
                    latitude: hgtFiles[1].getCoordinate().latitude + 1.0,
                    longitude: hgtFiles[1].getCoordinate().longitude + 1.0)
                overlayBottomLeftCoordinate = CLLocationCoordinate2D(
                    latitude: hgtFiles[0].getCoordinate().latitude,
                    longitude: hgtFiles[0].getCoordinate().longitude)
                
            } else if hgtFiles[0].coordinate.longitude == hgtFiles[1].coordinate.longitude {
                // 2x1
                overlayTopRightCoordinate = CLLocationCoordinate2D(
                    latitude: hgtFiles[0].getCoordinate().latitude + 1.0,
                    longitude: hgtFiles[0].getCoordinate().longitude + 1.0)
                overlayBottomLeftCoordinate = CLLocationCoordinate2D(
                    latitude: hgtFiles[1].getCoordinate().latitude,
                    longitude: hgtFiles[1].getCoordinate().longitude)
            }
        }
        
        var overlayBoundingMapRect: MKMapRect {
            get {
                let topLeft = MKMapPointForCoordinate(overlayTopLeftCoordinate)
                let topRight = MKMapPointForCoordinate(overlayTopRightCoordinate)
                let bottomLeft = MKMapPointForCoordinate(overlayBottomLeftCoordinate)
                
                return MKMapRectMake(topLeft.x,
                    topLeft.y,
                    fabs(topLeft.x - topRight.x),
                    fabs(topLeft.y - bottomLeft.y))
            }
        }
        
        return overlayBoundingMapRect
    }
    
    
}