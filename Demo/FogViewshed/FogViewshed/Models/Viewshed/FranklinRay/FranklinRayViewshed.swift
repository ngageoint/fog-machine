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
        var viewshed:[[Int]] = [[Int]](count:rowSize, repeatedValue:[Int](count:columnSize, repeatedValue:Srtm.NO_DATA))
        
        let oxiyi:(Int, Int) = elevationDataGrid.latLonToIndex(observer.position)
        // get the cell that the observer exists in
        let oxi:Int = oxiyi.0
        let oyi:Int = oxiyi.1
        var oh:Double = Double(elevationGrid[oxi][oyi]) + observer.elevationInMeters
        // FIXME: if there a better way to deal with this?
        // if the elevation data where the observer is positioned is bad, just set elevation to above sea level
        if(elevationGrid[oxi][oyi] == Srtm.DATA_VOID) {
            oh = observer.elevationInMeters
        }
        
        let oRadius:Double = observer.radiusInMeters
        
        let latAdjust:Double = elevationDataGrid.boundingBoxAreaExtent.getLowerLeft().latitude + ((1.0/Double(elevationDataGrid.resolution))*0.5)
        let lonAdjust:Double = elevationDataGrid.boundingBoxAreaExtent.getLowerLeft().longitude + ((1.0/Double(elevationDataGrid.resolution))*0.5)
        
        let olat:Double = (Double(oxi)*(1.0/Double(elevationDataGrid.resolution))) + latAdjust
        let olon:Double = (Double(oyi)*(1.0/Double(elevationDataGrid.resolution))) + lonAdjust
        
        // iterate through the cells c of the perimeter. Each c has coordinates (xc, yc, 0), where the corresponding point on the terrain is (xc, yc, zc).
        for (px, py) in getPerimeterCells() {
            // for each cell, find a line from the observer to the cell
            let lineCells:[(x:Int, y:Int)] = BresenhamsLineAlgoritm.findLine(x1: oxi, y1: oyi, x2: px, y2: py)
            
            // let mu be the greatest slope seen so far along this line. Initialize mu = − infinity
            var mu = -Double.infinity
            
            // iterate along the line from the observer to the cell on the perimeter
            for (xi, yi) in lineCells {
                
                // the observer can see itself, don't run this
                if(oxi == xi && oyi == yi) {
                    continue
                }
                
                let xyi:Int = elevationGrid[xi][yi]
                let xyh:Double = Double(xyi)
                
                // if the elevation data at this point is bad, we don't know if it's visible or not...
                if(xyi == Srtm.DATA_VOID) {
                    continue;
                }
                
                // get the longitude in the center of the cell:
                let xlat:Double = (Double(xi)*(1.0/Double(elevationDataGrid.resolution))) + latAdjust
                let ylon:Double = (Double(yi)*(1.0/Double(elevationDataGrid.resolution))) + lonAdjust
                
                let oppositeInMeters:Double = xyh - oh
                // FIXME : should this use haversine or vincenty?
                let adjacent:Double = GeoUtility.haversineDistanceInMeters(xlat, lon1: ylon, lat2: olat, lon2: olon)
                
                // is the cell with in the area of intrest?
                if(adjacent > oRadius) {
                    // neither visible or non-visible, outisde of the area of interest. Already set to no_data, break the inner loop.
                    break;
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
            var i:Int = 0
            while(i <= columnSize - 1) {
                perimeter.append((0, i))
                i = i + 1
            }
            
            // top left to top right (excludes corners)
            i = 1
            while(i <= rowSize - 2) {
                perimeter.append((i, columnSize - 1))
                i = i + 1
            }
            
            // top right to lower right
            i = columnSize - 1
            while(i >= 0) {
                perimeter.append((rowSize - 1, i))
                i = i - 1
            }
            
            // lower right to lower left (excludes corners)
            i = rowSize - 2
            while(i >= 1) {
                perimeter.append((i, 0))
                i = i - 1
            }
        }
        
        if(perimeterSize != perimeter.count) {
            NSLog("Perimeter was the wrong size! Expected: \(perimeterSize), received: \(perimeter.count)")
        }
        
        return perimeter
    }

}
