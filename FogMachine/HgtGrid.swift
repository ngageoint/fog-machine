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
    
    var observerPosition: GridPosition!
    var elevationCube: [[Int]]!
    var upperLeftHgt: Hgt!
    var lowerLeftHgt: Hgt!
    var upperRightHgt: Hgt!
    var lowerRightHgt: Hgt!
    var isSingleHgt: Bool = false
    
    
    init(singleHgt: Hgt) {
        super.init()
        self.isSingleHgt = true
        self.upperLeftHgt = singleHgt
        self.lowerLeftHgt = singleHgt
        self.upperRightHgt = singleHgt
        self.lowerRightHgt = singleHgt
        self.observerPosition = GridPosition.UpperLeft
        self.elevationCube = singleHgt.getElevation()
    }
    
    
    init(upperLeftHgt: Hgt, lowerLeftHgt: Hgt, upperRightHgt: Hgt, lowerRightHgt: Hgt, observerPosition: GridPosition) {
        super.init()
        self.isSingleHgt = false
        self.upperLeftHgt = upperLeftHgt
        self.lowerLeftHgt = lowerLeftHgt
        self.upperRightHgt = upperRightHgt
        self.lowerRightHgt = lowerRightHgt
        self.observerPosition = observerPosition
        self.elevationCube = combineElevations()
    }
    
    
    func configureGrid(upperLeftHgt: Hgt, lowerLeftHgt: Hgt, upperRightHgt: Hgt, lowerRightHgt: Hgt, observerPosition: GridPosition) {
        self.isSingleHgt = false
        self.upperLeftHgt = upperLeftHgt
        self.lowerLeftHgt = lowerLeftHgt
        self.upperRightHgt = upperRightHgt
        self.lowerRightHgt = lowerRightHgt
        self.observerPosition = observerPosition
        self.elevationCube = combineElevations()
    }
    
    
    func getHgtGridSize() -> Double {
        var hgtGridSize = 1.0
        if isSingleHgt {
            hgtGridSize = 0.0
        }
        
        return hgtGridSize
    }
    
    
    func getElevation() -> [[Int]] {
        return elevationCube
    }
    
    
    private func combineElevations() -> [[Int]] {
        var newElevationCube = [[Int]](count:Srtm3.MAX_SIZE * 2, repeatedValue:[Int](count:Srtm3.MAX_SIZE * 2, repeatedValue:0))
        
        var row = 0
        var column = 0
        let numCells = Srtm3.MAX_SIZE * Srtm3.MAX_SIZE * 4
        for (var cell = 0; cell < numCells; cell+=1) {
            
            if column < Srtm3.MAX_SIZE && row < Srtm3.MAX_SIZE {
                newElevationCube[row][column] = upperLeftHgt.elevation[row][column]
                
            } else if column < Srtm3.MAX_SIZE && row >= Srtm3.MAX_SIZE {
                newElevationCube[row][column] = lowerLeftHgt.elevation[row - Srtm3.MAX_SIZE][column]
                
            } else if column >= Srtm3.MAX_SIZE && row < Srtm3.MAX_SIZE {
                newElevationCube[row][column] = upperRightHgt.elevation[row][column - Srtm3.MAX_SIZE]
                
            } else if column >= Srtm3.MAX_SIZE && row >= Srtm3.MAX_SIZE {
                newElevationCube[row][column] = lowerRightHgt.elevation[row - Srtm3.MAX_SIZE][column - Srtm3.MAX_SIZE]
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
        
        return newElevationCube
    }
    
    
    func getHgtCoordinate() -> CLLocationCoordinate2D {
        return upperLeftHgt.getCoordinate()
    }
    
}