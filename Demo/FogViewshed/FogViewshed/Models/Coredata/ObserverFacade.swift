import Foundation
import CoreData
import UIKit

class ObserverFacade {
    
    let defaults = NSUserDefaults.standardUserDefaults()
    
    var managedContext: NSManagedObjectContext {
        return (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!
    }
    
    func clearEntity() {
        let request = NSFetchRequest(entityName: "Observer")
        request.returnsObjectsAsFaults = false
        
        do {
            let deleteRequest = try managedContext.executeFetchRequest(request)
            
            if deleteRequest.count > 0 {
                for result: AnyObject in deleteRequest {
                    managedContext.deleteObject(result as! NSManagedObject)
                    saveContext()
                }
            }
        } catch let error as NSError {
            print("Error clearing observer entity " + " \(error): \(error.userInfo)")
        }
    }
    
    func delete(observer: Observer) {
        for observerEntity:ObserverEntity in getObserverEntities() {
            if(observer == observerEntity.asObserver()) {
                managedContext.deleteObject(observerEntity)
                saveContext()
                break;
            }
        }
    }
    
    func add(observer: Observer) -> Bool {
        if(getObservers().contains(observer)) {
            return false
        } else {
            let managedObject = NSEntityDescription.insertNewObjectForEntityForName("Observer", inManagedObjectContext: managedContext) as NSManagedObject
            managedObject.setValue(observer.uniqueId, forKey: "uniqueId")
            managedObject.setValue(observer.elevationInMeters, forKey: "elevationInMeters")
            managedObject.setValue(observer.radiusInMeters, forKey: "radiusInMeters")
            managedObject.setValue(observer.position.latitude, forKey: "latitude")
            managedObject.setValue(observer.position.longitude, forKey: "longitude")
            saveContext()
            return true
        }
    }
    
    func add(observers: [Observer]) {
        for observer in observers {
            add(observer)
        }
    }
    
    private func saveContext() {
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save " + " \(error): \(error.userInfo)")
        }
    }
    
    private func getObserverEntities()-> [ObserverEntity] {
        var observerEntities:[ObserverEntity] = [ObserverEntity]()
        let fetchRequest = NSFetchRequest(entityName: "Observer")
        fetchRequest.returnsObjectsAsFaults = false
        do {
            let fetchResults = try managedContext.executeFetchRequest(fetchRequest) as? [ObserverEntity]
            
            if let _ = fetchResults {
                observerEntities.appendContentsOf(fetchResults!)
            }
            
        } catch let error as NSError {
            print("Error fetching observer entities " + " \(error): \(error.userInfo)")
        }
        return observerEntities
    }
    
    func getObservers()-> [Observer] {
        var observers:[Observer] = [Observer]()
        for observerEntity:ObserverEntity in getObserverEntities() {
            observers.append(observerEntity.asObserver())
        }
        observers.sortInPlace { (obj1, obj2) -> Bool in
            return obj1.uniqueId < obj2.uniqueId
        }

        return observers
    }
}
