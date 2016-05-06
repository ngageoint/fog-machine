import Foundation
import MapKit

public class ElevationDataGrid {
    
    let elevationData: [[Int]]
    
    // this bounding box coveres the entire of the grid
    // When drawing or positioning the data, this information can be used to offset the elevation grid.  It says where the grid is pined to the earth
    let boundingBoxAreaExtent:AxisOrientedBoundingBox
    
    let resolution:Int
    
    init(elevationData: [[Int]], boundingBoxAreaExtent:AxisOrientedBoundingBox, resolution:Int) {
        self.elevationData = elevationData
        self.boundingBoxAreaExtent = boundingBoxAreaExtent
        self.resolution = resolution
    }
    
    func latLonToIndex(latLon:CLLocationCoordinate2D) -> (Int, Int) {
        return HGTManager.latLonToIndex(latLon, boundingBox: boundingBoxAreaExtent, resolution: Double(resolution))
    }
}