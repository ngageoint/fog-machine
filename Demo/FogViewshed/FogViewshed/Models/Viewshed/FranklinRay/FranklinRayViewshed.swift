import UIKit
import MapKit

/**
 
 Finds a viewshed using Franklin and Ray's method.  Less acurate, but fast.
 
 */
public class FranklinRayViewshed : ViewsehdAlgorithm {

    let elevationDataGrid: DataGrid
    let observer: Observer
    
    private let rowSize:Int
    private let columnSize:Int
    private var perimeterSize:Int
    
    init(elevationDataGrid: DataGrid, observer: Observer) {
        self.elevationDataGrid = elevationDataGrid
        self.observer = observer
        
        self.rowSize = elevationDataGrid.data.count
        self.columnSize = elevationDataGrid.data[0].count
        self.perimeterSize = 1
        
        if(rowSize == 1 && columnSize == 1) {
            self.perimeterSize = 1
        } else if(rowSize == 1) {
            self.perimeterSize = columnSize
        } else if(columnSize == 1) {
            self.perimeterSize = rowSize
        } else {
            self.perimeterSize = 2*(rowSize + columnSize - 2)
        }
    }
    
    /**
 
     Runs the franklin ray viewshed algorithm
     
     see http://www.cs.rpi.edu/~cutler/publications/andrade_geoinformatica.pdf
    
     Given a terrain T represented by an n × n elevation matrix M, a point p on T , a radius of interest r, and a height h above the local terrain for the observer and target, this algorithm computes the viewshed of p within a distance r of p.
     
     */
    public func runViewshed() -> [[Int]] {
        // inputs
        let elevationGrid: [[Int]] = elevationDataGrid.data
        
        let oxiyi:(Int, Int) = elevationDataGrid.latLonToIndex(observer.position)
        // get the cell that the observer exists in
        let oxi:Int = oxiyi.1
        let oyi:Int = oxiyi.0
        var oh:Double = Double(elevationGrid[oxi][oyi]) + observer.elevationInMeters
        // FIXME: if there a better way to deal with this?
        // if the elevation data where the observer is positioned is bad, just set elevation to above sea level
        if(elevationGrid[oxi][oyi] == Srtm.DATA_VOID) {
            oh = observer.elevationInMeters
        }
        
        // outputs
        var viewshed:[[Int]] = [[Int]](count:rowSize, repeatedValue:[Int](count:columnSize, repeatedValue:Viewshed.NO_DATA))
        viewshed[oxi][oyi] = Viewshed.OBSERVER
        
        let oRadius:Double = observer.radiusInMeters
        
        let latAdjust:Double = elevationDataGrid.boundingBoxAreaExtent.getLowerLeft().latitude + ((1.0/Double(elevationDataGrid.resolution))*0.5)
        let lonAdjust:Double = elevationDataGrid.boundingBoxAreaExtent.getLowerLeft().longitude + ((1.0/Double(elevationDataGrid.resolution))*0.5)
        
        let olat:Double = (Double(oxi)*(1.0/Double(elevationDataGrid.resolution))) + latAdjust
        let olon:Double = (Double(oyi)*(1.0/Double(elevationDataGrid.resolution))) + lonAdjust
        
        // iterate through the cells c of the perimeter. Each c has coordinates (xc, yc, 0), where the corresponding point on the terrain is (xc, yc, zc).
        while(hasAnotherPerimeterCell()) {
            let (px,py):(Int,Int) = getNextPerimeterCell()
            // NSLog("(px, py): (\(px), \(py))  ::  \(perimeterCellIndex)  \(perimeterSize)")
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
                
                if(xyi == Srtm.NO_DATA) { // if there is no data at this point, we can not continue the running this line
                    break;
                } else if(xyi == Srtm.DATA_VOID) { // if the elevation data at this point is bad, we don't know if it's visible or not...
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
                        viewshed[xi][yi] = Viewshed.NOT_VISIBLE
                    } else {
                        // visible
                        viewshed[xi][yi] = Viewshed.VISIBLE
                        mu = xymu
                    }
                }
            }
        }
        
        return viewshed
    }
    
    private var perimeterCellIndex: Int = -1;
    
    private func hasAnotherPerimeterCell() -> Bool {
        return (perimeterCellIndex < perimeterSize)
    }
    
    private func getNextPerimeterCell() -> (x:Int,y:Int) {
        if(hasAnotherPerimeterCell()) {
            perimeterCellIndex += 1
            var i:Int = perimeterCellIndex
            
            if(i <= columnSize - 1) {
                return(0, i)
            }
            i -= columnSize - 1
            if(i <= rowSize - 1) {
                return(i, columnSize - 1)
            }
            
            i -= rowSize - 1
            if(i <= columnSize - 1) {
                return(rowSize - 1, columnSize - 1 - i)
            }
            
            i -= columnSize - 1
            return(rowSize - 1 - i, 0)
        }
        return (0,0)
    }
    
//    private func getPerimeterCells() -> [(x:Int,y:Int)] {
//        // Perimeter goes clockwise from the lower left coordinate
//        var perimeter:[(x:Int, y:Int)] = []
//        
//        if(perimeterSize == 1) {
//            perimeter.append((0,0))
//        } else {
//            // lower left to top left
//            var i:Int = 0
//            while(i <= columnSize - 1) {
//                perimeter.append((0, i))
//                i = i + 1
//            }
//            
//            // top left to top right (excludes corners)
//            i = 1
//            while(i <= rowSize - 2) {
//                perimeter.append((i, columnSize - 1))
//                i = i + 1
//            }
//            
//            // top right to lower right
//            i = columnSize - 1
//            while(i >= 0) {
//                perimeter.append((rowSize - 1, i))
//                i = i - 1
//            }
//            
//            // lower right to lower left (excludes corners)
//            i = rowSize - 2
//            while(i >= 1) {
//                perimeter.append((i, 0))
//                i = i - 1
//            }
//        }
//        
//        if(perimeterSize != perimeter.count) {
//            NSLog("Perimeter was the wrong size! Expected: \(perimeterSize), received: \(perimeter.count)")
//        }
//        
//        return perimeter
//    }

}
