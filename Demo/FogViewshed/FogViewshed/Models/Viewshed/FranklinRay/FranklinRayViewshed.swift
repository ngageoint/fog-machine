import UIKit
import MapKit

/**
 
 Finds a viewshed using Franklin and Ray's method.  Less acurate, but fast.
 
 */
public class FranklinRayViewshed : ViewsehdAlgorithm {

    let elevationDataGrid: DataGrid
    let perimeter: Perimeter;
    let observer: Observer
    
    init(elevationDataGrid: DataGrid, perimeter: Perimeter, observer: Observer) {
        self.elevationDataGrid = elevationDataGrid
        self.observer = observer
        self.perimeter = perimeter
    }
    
    /**
 
     Runs the Franklin and Ray's viewshed algorithm
     
     see http://www.cs.rpi.edu/~cutler/publications/andrade_geoinformatica.pdf
    
     Given a terrain T represented by an n × n elevation matrix M, a point p on T, a radius of interest r, and a height h above the local terrain for the observer and target, this algorithm computes the viewshed of p within a distance r of p.
     
     */
    public func runViewshed() -> DataGrid {
        // inputs
        let elevationGrid: [[Int]] = elevationDataGrid.data
        
        let resolutionInverse:Double = (1.0/Double(elevationDataGrid.resolution))
        
        let rowSize:Int =  elevationDataGrid.data.count
        let columnSize:Int = elevationDataGrid.data[0].count
        
        let oxiyi:(Int, Int) = elevationDataGrid.latLonToIndex(observer.position)
        // get the cell the observer exists in
        let oxi:Int = oxiyi.0
        let oyi:Int = oxiyi.1
        var oh:Double = Double(elevationGrid[oyi][oxi]) + observer.elevationInMeters
        // FIXME: if there a better way to deal with this?
        // if the elevation data where the observer is positioned is bad, just set elevation to above sea level
        if(elevationGrid[oyi][oxi] == Srtm.DATA_VOID) {
            oh = observer.elevationInMeters
        }
        
        // outputs
        var viewshed:[[Int]] = [[Int]](count:rowSize, repeatedValue:[Int](count:columnSize, repeatedValue:Viewshed.NO_DATA))
        viewshed[oyi][oxi] = Viewshed.OBSERVER
        
        
        // vars
        let oRadius:Double = observer.radiusInMeters
        
        let latAdjust:Double = elevationDataGrid.boundingBoxAreaExtent.getLowerLeft().latitude + (resolutionInverse*0.5)
        let lonAdjust:Double = elevationDataGrid.boundingBoxAreaExtent.getLowerLeft().longitude + (resolutionInverse*0.5)
        
        // at the center of the cell
        let olat:Double = (Double(oyi)*resolutionInverse) + latAdjust
        let olon:Double = (Double(oxi)*resolutionInverse) + lonAdjust
        
        //let radiusOfEarth:Double = GeoUtility.earthRadiusAtLat(olat)
        //let radiusOfEarthSquared:Double = pow(radiusOfEarth, 2)
        
        //let euclideanDistanceToHorizonInMeters:Double = sqrt(pow(radiusOfEarth + oh,2) - radiusOfEarthSquared)
        
        // iterate through the cells c of the perimeter. Each c has coordinates (xc, yc, 0), where the corresponding point on the terrain is (xc, yc, zc).
        while(perimeter.hasAnotherPerimeterCell()) {
            let (px,py):(Int,Int) = perimeter.getNextPerimeterCell()
            // NSLog("(px, py): (\(px), \(py))")
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
                
                let xyi:Int = elevationGrid[yi][xi]
                let xyh:Double = Double(xyi)
                
                if(xyi == Srtm.NO_DATA) { // if there is no data at this point, we can not continue processing this line
                    break;
                } else if(xyi == Srtm.DATA_VOID) { // if the elevation data at this point is bad, we don't know if it's visible or not...
                    continue;
                }
                
                // get the longitude in the center of the cell
                let ylat:Double = (Double(yi)*resolutionInverse) + latAdjust
                let xlon:Double = (Double(xi)*resolutionInverse) + lonAdjust
                
                let oppositeInMeters:Double = xyh - oh
                // FIXME : should this likely use euclidean distance based on a ecef or spherical model of the earth...
                let adjacentInMeters:Double = GeoUtility.haversineDistanceInMeters(ylat, lon1: xlon, lat2: olat, lon2: olon)
                
                // FIXME : make sure points beyond the horizon can be seen
                let beyondHorizonAndNotVisible:Bool = false
                
//                if(adjacentInMeters > euclideanDistanceToHorizonInMeters) {
//                    let minimumElevationToBeVisible:Double = sqrt(pow((adjacentInMeters - euclideanDistanceToHorizonInMeters),2) + radiusOfEarthSquared) - radiusOfEarth
//                    if(xyh < minimumElevationToBeVisible) {
//                        beyondHorizonAndNotVisible = true
//                    }
//                }
                
                // is the cell within the area of interest?
                if(adjacentInMeters > oRadius) {
                    // neither visible or non-visible, outisde of the area of interest. Already set to no_data, break the inner loop.
                    break;
                } else {
                    // find the slope of the line from the current cell to the observer
                    let xymu:Double = oppositeInMeters/adjacentInMeters
                    
                    // If xymu < mu, then this cell is not visible, otherwise, mark the cell visible
                    if (beyondHorizonAndNotVisible || xymu < mu) {
                        // not visible
                        viewshed[yi][xi] = Viewshed.NOT_VISIBLE
                    } else {
                        // visible
                        viewshed[yi][xi] = Viewshed.VISIBLE
                        mu = xymu
                    }
                }
            }
        }
        
        return DataGrid(data: viewshed, boundingBoxAreaExtent: elevationDataGrid.boundingBoxAreaExtent, resolution: elevationDataGrid.resolution)
    }
}
