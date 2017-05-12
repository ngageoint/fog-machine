import Foundation
import MapKit

open class Observer: NSObject, NSCoding {
    
    open var uniqueId: String = UUID().uuidString
    open var elevationInMeters: Double = 1.6
    open var radiusInMeters: Double = 30000.0
    open var position: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0.0, 0.0)
    
    override init() {
        
    }
    
    init(elevationInMeters: Double, radiusInMeters: Double, position: CLLocationCoordinate2D) {
        self.elevationInMeters = elevationInMeters
        self.radiusInMeters = radiusInMeters
        self.position = position
    }
    
    // MARK: FMCoding
    required public init(coder decoder: NSCoder) {
        uniqueId = decoder.decodeObject(forKey: "uniqueId") as! String
        elevationInMeters = decoder.decodeDouble(forKey: "elevationInMeters")
        radiusInMeters = decoder.decodeDouble(forKey: "radiusInMeters")
        position = CLLocationCoordinate2DMake(decoder.decodeDouble(forKey: "latitude"), decoder.decodeDouble(forKey: "longitude"))
    }
    
    open func encode(with coder: NSCoder) {
        coder.encode(uniqueId, forKey: "uniqueId")
        coder.encode(elevationInMeters, forKey: "elevationInMeters")
        coder.encode(radiusInMeters, forKey: "radiusInMeters")
        coder.encode(position.latitude, forKey: "latitude")
        coder.encode(position.longitude, forKey: "longitude")
    }
    
    // MARK: CustomStringConvertible
    
    /// lat, lon fo the observer
    override open var description: String {
        return String(format: "%.4f", position.latitude) + ", " + String(format: "%.4f", position.longitude)
    }
    
    override open func isEqual(_ object: Any?) -> Bool {
        if let object = object as? Observer {
            return uniqueId == object.uniqueId
        } else {
            return false
        }
    }
    
    override open var hash: Int {
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
