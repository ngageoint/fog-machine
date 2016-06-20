import Foundation
import MapKit

public class Observer : NSObject, NSCoding {
    
    var id:Int = 1
    var name:String {
     return "Observer \(id)"
    }
    var elevationInMeters:Double = 1.6
    var radiusInMeters:Double = 30000.0
    var position:CLLocationCoordinate2D = CLLocationCoordinate2DMake(0.0, 0.0)
    
    override init() {
        
    }
    
    init(id:Int, elevationInMeters: Double, radiusInMeters: Double, position: CLLocationCoordinate2D) {
        self.id = id
        self.elevationInMeters = elevationInMeters
        self.radiusInMeters = radiusInMeters
        self.position = position
    }
    
    required public init(coder decoder: NSCoder) {
        self.id = decoder.decodeIntegerForKey("id")
        self.elevationInMeters = decoder.decodeDoubleForKey("elevationInMeters")
        self.radiusInMeters = decoder.decodeDoubleForKey("radiusInMeters")
        self.position = CLLocationCoordinate2DMake(decoder.decodeDoubleForKey("latitude"), decoder.decodeDoubleForKey("longitude"))
    }
    
    public func encodeWithCoder(coder: NSCoder) {
        coder.encodeInteger(id, forKey: "id")
        coder.encodeDouble(elevationInMeters, forKey: "elevationInMeters")
        coder.encodeDouble(radiusInMeters, forKey: "radiusInMeters")
        coder.encodeDouble(position.latitude, forKey: "latitude")
        coder.encodeDouble(position.longitude, forKey: "longitude")
    }
}