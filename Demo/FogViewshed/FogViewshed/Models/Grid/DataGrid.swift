import Foundation
import MapKit

open class DataGrid: NSObject, NSCoding {
    
    let data: [[Int]]
    
    // Bounding box covers the entirety of the grid
    // When drawing or positioning the data, this information can be used to offset the elevation grid.  It says where the grid is pinned to the earth.
    let boundingBoxAreaExtent: AxisOrientedBoundingBox
    
    let resolution: Int
    
    init(data: [[Int]], boundingBoxAreaExtent:AxisOrientedBoundingBox, resolution: Int) {
        self.data = data
        self.boundingBoxAreaExtent = boundingBoxAreaExtent
        self.resolution = resolution
    }
    
    func latLonToIndex(_ latLon:CLLocationCoordinate2D) -> (Int, Int) {
        return HGTManager.latLonToIndex(latLon, boundingBox: boundingBoxAreaExtent, resolution: resolution)
    }
    
    required public init(coder decoder: NSCoder) {
        data = decoder.decodeObject(forKey: "data") as! [[Int]]
        boundingBoxAreaExtent = decoder.decodeObject(forKey: "boundingBoxAreaExtent") as! AxisOrientedBoundingBox
        resolution = decoder.decodeObject(forKey: "resolution") as! Int
    }
    
    open func encode(with coder: NSCoder) {
        coder.encode(data, forKey: "data")
        coder.encode(boundingBoxAreaExtent, forKey: "boundingBoxAreaExtent")
        coder.encode(resolution, forKey: "resolution")
    }
}
