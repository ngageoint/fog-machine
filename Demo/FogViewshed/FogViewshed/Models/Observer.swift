import Foundation
import MapKit

public class Observer : NSObject, NSCoding {
    
    var name: String = "ObserverName"
    var elevationInMeters:Double = 1.0
    var radiusInMeters:Double = 20000.0
    var position: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0.0, 0.0)
    
    override init() {
        
    }
    
    init(name: String, elevationInMeters: Double, radiusInMeters: Double, position: CLLocationCoordinate2D) {
        self.name = name
        self.elevationInMeters = elevationInMeters
        self.radiusInMeters = radiusInMeters
        self.position = position
    }
    
    required public init(coder decoder: NSCoder) {
        self.name = decoder.decodeObjectForKey("name") as! String
        self.elevationInMeters = decoder.decodeDoubleForKey("elevationInMeters")
        self.radiusInMeters = decoder.decodeDoubleForKey("radiusInMeters")
        self.position = CLLocationCoordinate2DMake(decoder.decodeDoubleForKey("latitude"), decoder.decodeDoubleForKey("longitude"))
    }
    
    public func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(name, forKey: "name")
        coder.encodeDouble(elevationInMeters, forKey: "elevationInMeters")
        coder.encodeDouble(radiusInMeters, forKey: "radiusInMeters")
        coder.encodeDouble(position.latitude, forKey: "latitude")
        coder.encodeDouble(position.longitude, forKey: "longitude")
    }
}