import Foundation
import CoreData
import UIKit

class ObserverFacade {
    
    let defaults = UserDefaults.standard
    
    var managedContext: NSManagedObjectContext {
        return (UIApplication.shared.delegate as! AppDelegate).managedObjectContext!
    }
    
    func clearEntity() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Observer")
        request.returnsObjectsAsFaults = false
        
        do {
            let deleteRequest = try managedContext.fetch(request)
            
            if deleteRequest.count > 0 {
                for result: Any in deleteRequest {
                    managedContext.delete(result as! NSManagedObject)
                    saveContext()
                }
            }
        } catch let error as NSError {
            print("Error clearing observer entity " + " \(error): \(error.userInfo)")
        }
    }
    
    func delete(_ observer: Observer) {
        for observerEntity: ObserverEntity in getObserverEntities() {
            if(observer == observerEntity.asObserver()) {
                managedContext.delete(observerEntity)
                saveContext()
                break
            }
        }
    }
    
    func add(_ observer: Observer) -> Bool {
        if(getObservers().contains(observer)) {
            return false
        } else {
            let managedObject = NSEntityDescription.insertNewObject(forEntityName: "Observer", into: managedContext) as NSManagedObject
            managedObject.setValue(observer.uniqueId, forKey: "uniqueId")
            managedObject.setValue(observer.elevationInMeters, forKey: "elevationInMeters")
            managedObject.setValue(observer.radiusInMeters, forKey: "radiusInMeters")
            managedObject.setValue(observer.position.latitude, forKey: "latitude")
            managedObject.setValue(observer.position.longitude, forKey: "longitude")
            saveContext()
            return true
        }
    }
    
    func add(_ observers: [Observer]) {
        for observer in observers {
            _ = add(observer)
        }
    }
    
    fileprivate func saveContext() {
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save " + " \(error): \(error.userInfo)")
        }
    }
    
    fileprivate func getObserverEntities()-> [ObserverEntity] {
        var observerEntities: [ObserverEntity] = [ObserverEntity]()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Observer")
        fetchRequest.returnsObjectsAsFaults = false
        do {
            let fetchResults = try managedContext.fetch(fetchRequest) as? [ObserverEntity]
            
            if let _ = fetchResults {
                observerEntities.append(contentsOf: fetchResults!)
            }
            
        } catch let error as NSError {
            print("Error fetching observer entities " + " \(error): \(error.userInfo)")
        }
        return observerEntities
    }
    
    func getObservers()-> [Observer] {
        var observers: [Observer] = [Observer]()
        for observerEntity: ObserverEntity in getObserverEntities() {
            observers.append(observerEntity.asObserver())
        }
        observers.sort { (obj1, obj2) -> Bool in
            return obj1.uniqueId < obj2.uniqueId
        }

        return observers
    }
}
