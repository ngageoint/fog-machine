import Foundation
import CoreData
import MapKit

@objc(ObserverEntity)
class ObserverEntity: NSManagedObject {
    
    @NSManaged var uniqueId: String
    @NSManaged var elevationInMeters: Double
    @NSManaged var radiusInMeters: Double
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    
    func asObserver() -> Observer {
        let observer:Observer = Observer(elevationInMeters: elevationInMeters, radiusInMeters: radiusInMeters, position: CLLocationCoordinate2DMake(latitude, longitude))
        observer.uniqueId = uniqueId
        return observer
    }
}
