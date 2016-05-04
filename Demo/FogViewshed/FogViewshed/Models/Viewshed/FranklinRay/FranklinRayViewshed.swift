import UIKit
import MapKit


/**
 
 Finds a viewshed using Franklin and Ray's method.  Less acurate, but fast.
 
 */
public class FranklinRayViewshed : ViewsehdAlgorithm {

    let elevationDataGrid: ElevationDataGrid
    let observer: Observer
    
    init(elevationDataGrid: ElevationDataGrid, observer: Observer) {
        self.elevationDataGrid = elevationDataGrid
        self.observer = observer
    }
    
    /**
 
     Runs the franklin ray viewshed algorithm
     
     see http://www.cs.rpi.edu/~cutler/publications/andrade_geoinformatica.pdf
    
     Given a terrain T represented by an n × n elevation matrix M, a point p on T , a radius of interest r, and a height h above the local terrain for the observer and target, this algorithm computes the viewshed of p within a distance r of p.
     
     */
    public func runViewshed() -> [[Int]] {
        
        let elevationGrid: [[Int]] = elevationDataGrid.elevationData
        
        let rowSize = elevationGrid.count
        let columnSize = elevationGrid[0].count
        var viewshed:[[Int]] = [[Int]](count:rowSize, repeatedValue:[Int](count:columnSize, repeatedValue:0))
        
        // get the cell that the observer exists in
        let oxi:Int = 600
        let oyi:Int = 600
        let oh:Double = Double(elevationGrid[oxi][oyi]) + observer.elevationInMeters
        let oRadius:Double = observer.radiusInMeters
        
        let latAdjust:Double = elevationDataGrid.boundingBoxAreaExtent.getLowerLeft().latitude + ((1.0/Double(elevationDataGrid.resolution))*0.5)
        let lonAdjust:Double = elevationDataGrid.boundingBoxAreaExtent.getLowerLeft().longitude + ((1.0/Double(elevationDataGrid.resolution))*0.5)
        
        let olat:Double = (Double(oxi)*(1.0/Double(elevationDataGrid.resolution))) + latAdjust
        let olon:Double = Double(oyi)*(1.0/Double(elevationDataGrid.resolution)) + lonAdjust
        
        // iterate through the cells c of the perimeter. Each c has coordinates (xc, yc, 0), where the corresponding point on the terrain is (xc, yc, zc).
        for (px, py) in getPerimeterCells() {
            // for each cell, find a line from the observer to the cell
            let lineCells:[(x:Int, y:Int)] = BresenhamsLineAlgoritm.findLine(x1: oxi, y1: oyi, x2: px, y2: py)
            
            // let mu be the greatest slope seen so far along this line. Initialize mu = − infinity
            var mu = -Double.infinity
            
            // iterate along the line from the observer to the cell on the perimeter
            for (xi, yi) in lineCells {
                let xyh:Double = Double(elevationGrid[xi][yi])
                
                // get the longitude in the center of the cell:
                let xlat:Double = (Double(xi)*(1.0/Double(elevationDataGrid.resolution))) + latAdjust
                let ylon:Double = (Double(yi)*(1.0/Double(elevationDataGrid.resolution))) + latAdjust
                
                let oppositeInMeters:Double = xyh - oh
                // FIXME : should this use haversine or vincenty?
                let adjacent:Double = GeoUtility.haversineDistanceInMeters(xlat, lon1: ylon, lat2: olat, lon2: olon)
                
                // is the cell with in the area of intrest?
                if(adjacent > oRadius) {
                    // neither visible or non-visible, outisde of the area of interest
                    viewshed[xi][yi] = -1
                } else {
                    // find the slope of the line from the current cell to the observer
                    let xymu:Double = oppositeInMeters/adjacent
                    
                    // If xymu < mu, then this cell is not visible, otherwise, mark the cell is visible
                    if (xymu < mu) {
                        // not visible
                        viewshed[xi][yi] = 0
                    } else {
                        // visible
                        viewshed[xi][yi] = 1
                        mu = xymu
                    }
                }
            }
        }
        
        return viewshed
    }
    
    private func getPerimeterCells() -> [(x:Int,y:Int)] {
        let elevationGrid: [[Int]] = elevationDataGrid.elevationData
        let rowSize:Int = elevationGrid.count
        let columnSize:Int = elevationGrid[0].count
        
        var perimeterSize = 2*(rowSize + columnSize - 2)
        
        if(rowSize == 1 && columnSize == 1) {
            perimeterSize = 1
        }
        
        // Perimeter goes clockwise from the lower left coordinate
        var perimeter:[(x:Int, y:Int)] = []
        
        if(perimeterSize == 1) {
            perimeter.append((0,0))
        } else {
            // lower left to top left
            for i in 0.stride(to: columnSize - 1, by: 1) {
                perimeter.append((i, 0))
            }
            // top left to top right (excludes corners)
            for i in 1.stride(to: rowSize - 2, by: 1) {
                perimeter.append((columnSize - 1, i))
            }
            // top right to lower right
            for i in (columnSize - 1).stride(to: 0, by: -1) {
                perimeter.append((i, rowSize - 1))
            }
            // lower right to lower left (excludes corners)
            for i in (rowSize - 2).stride(to: 1, by: -1) {
                perimeter.append((0, i))
            }
        }
        
        if(perimeterSize != perimeter.count) {
            NSLog("Perimeter was the wrong size!")
        }
        
        return perimeter
    }

}
