import Foundation
import MapKit

public class Observer : NSObject, NSCoding {
    
    public var uniqueId:String = NSUUID().UUIDString
    public var elevationInMeters:Double = 1.6
    public var radiusInMeters:Double = 30000.0
    public var position:CLLocationCoordinate2D = CLLocationCoordinate2DMake(0.0, 0.0)
    
    override init() {
        
    }
    
    init(elevationInMeters: Double, radiusInMeters: Double, position: CLLocationCoordinate2D) {
        self.elevationInMeters = elevationInMeters
        self.radiusInMeters = radiusInMeters
        self.position = position
    }
    
    // MARK: FMCoding
    required public init(coder decoder: NSCoder) {
        self.uniqueId = decoder.decodeObjectForKey("uniqueId") as! String
        self.elevationInMeters = decoder.decodeDoubleForKey("elevationInMeters")
        self.radiusInMeters = decoder.decodeDoubleForKey("radiusInMeters")
        self.position = CLLocationCoordinate2DMake(decoder.decodeDoubleForKey("latitude"), decoder.decodeDoubleForKey("longitude"))
    }
    
    public func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(uniqueId, forKey: "uniqueId")
        coder.encodeDouble(elevationInMeters, forKey: "elevationInMeters")
        coder.encodeDouble(radiusInMeters, forKey: "radiusInMeters")
        coder.encodeDouble(position.latitude, forKey: "latitude")
        coder.encodeDouble(position.longitude, forKey: "longitude")
    }
    
    // MARK: CustomStringConvertible
    
    /// lat, lon fo the observer
    override public var description: String {
        return String(format: "%.4f", position.latitude) + ", " + String(format: "%.4f", position.longitude)
    }
    
    override public func isEqual(object: AnyObject?) -> Bool {
        if let object = object as? Observer {
            return uniqueId == object.uniqueId
        } else {
            return false
        }
    }
    
    override public var hash: Int {
        return uniqueId.hashValue
    }
}

/**
 Determines if two Observers are equivalent
 
 - parameter lhs: left-hand Observer
 - parameter rhs: right-hand Observer
 
 - returns: true iff the lhs.uniqueId == rhs.uniqueId, false otherwise
 */
public func ==(lhs: Observer, rhs: Observer) -> Bool {
    return lhs.uniqueId == rhs.uniqueId
}