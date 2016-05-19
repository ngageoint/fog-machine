import Foundation
import MapKit

public class DataGrid : NSObject, NSCoding {
    
    let data: [[Int]]
    
    // Bounding box covers the entirety of the grid
    // When drawing or positioning the data, this information can be used to offset the elevation grid.  It says where the grid is pinned to the earth.
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
    
    required public init(coder decoder: NSCoder) {
        self.data = decoder.decodeObjectForKey("data") as! [[Int]]
        self.boundingBoxAreaExtent = decoder.decodeObjectForKey("boundingBoxAreaExtent") as! AxisOrientedBoundingBox
        self.resolution = decoder.decodeObjectForKey("resolution") as! Int
    }
    
    public func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(self.data, forKey: "data")
        coder.encodeObject(self.boundingBoxAreaExtent, forKey: "boundingBoxAreaExtent")
        coder.encodeObject(self.resolution, forKey: "resolution")
    }
}