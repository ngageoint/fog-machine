import Foundation
import CoreData
import MapKit

@objc(ObserverEntity)
class ObserverEntity: NSManagedObject {
    
    @NSManaged var name: String
    @NSManaged var elevationInMeters: Double
    @NSManaged var radiusInMeters: Double
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    
    func asObserver() -> Observer {
        return Observer(name: name, elevationInMeters: elevationInMeters, radiusInMeters: radiusInMeters, position: CLLocationCoordinate2DMake(latitude, longitude))
    }
}
