import Foundation
import MapKit

public class DataGrid {
    
    let data: [[Int]]
    
    // this bounding box coveres the entire of the grid
    // When drawing or positioning the data, this information can be used to offset the elevation grid.  It says where the grid is pined to the earth
    let boundingBoxAreaExtent:AxisOrientedBoundingBox
    
    let resolution:Int
    
    init(data: [[Int]], boundingBoxAreaExtent:AxisOrientedBoundingBox, resolution:Int) {
        self.data = data
        self.boundingBoxAreaExtent = boundingBoxAreaExtent
        self.resolution = resolution
    }
    
    func latLonToIndex(latLon:CLLocationCoordinate2D) -> (Int, Int) {
        return HGTManager.latLonToIndex(latLon, boundingBox: boundingBoxAreaExtent, resolution: resolution)
    }
}