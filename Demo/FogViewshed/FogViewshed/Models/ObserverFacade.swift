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
    
    
    func delete(observer: ObserverEntity) {
        managedContext.deleteObject(observer)
        saveContext()
    }
    
    func add(observer: Observer) {
        let managedObject = NSEntityDescription.insertNewObjectForEntityForName("Observer", inManagedObjectContext: managedContext) as NSManagedObject
        managedObject.setValue(observer.name, forKey: "name")
        managedObject.setValue(observer.elevationInMeters, forKey: "elevationInMeters")
        managedObject.setValue(observer.radiusInMeters, forKey: "radiusInMeters")
        managedObject.setValue(observer.position.latitude, forKey: "latitude")
        managedObject.setValue(observer.position.longitude, forKey: "longitude")
    
        saveContext()
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
    
    func getObservers()-> [Observer] {
        var observers:[Observer] = [Observer]()
        var observerEntities:[ObserverEntity] = [ObserverEntity]()
        let fetchRequest = NSFetchRequest(entityName: "Observer")
        fetchRequest.returnsObjectsAsFaults = false
        do {
            let fetchResults = try managedContext.executeFetchRequest(fetchRequest) as? [ObserverEntity]

            if let _ = fetchResults {
                observerEntities = fetchResults!
            }
            
        } catch let error as NSError {
            print("Error fetching observer entity " + " \(error): \(error.userInfo)")
        }
        for observerEntity:ObserverEntity in observerEntities {
            observers.append(observerEntity.asObserver())
        }
        
        return observers
    }
}
