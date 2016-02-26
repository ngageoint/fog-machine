//
//  ObserverFacade.swift
//  FogMachine
//
//  Created by Chris Wasko on 1/27/16.
//  Copyright © 2016 NGA. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class ObserverFacade {
    
    var observers = [ObserverEntity]()
    let defaults = NSUserDefaults.standardUserDefaults()
    
    var managedContext: NSManagedObjectContext {
        return (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!
    }
    
    
    func populateEntity(newObservers: [Observer]) {
        guard newObservers.count > 0 else {
            return
        }
        addObservers(newObservers)
    }
    
    
    func populateEntity(newObserver: Observer) {
        addObserver(newObserver)
    }
    
    
    func clearEntity() {
        let request = NSFetchRequest(entityName: FogViewshed.ENTITY)
        request.returnsObjectsAsFaults = false
        
        do {
            let deleteRequest = try managedContext.executeFetchRequest(request)
            
            if deleteRequest.count > 0 {
                
                for result: AnyObject in deleteRequest {
                    managedContext.deleteObject(result as! NSManagedObject)
                }
                
                saveContext(managedContext)
            }
        } catch let error as NSError {
            logError("Error clearing \(FogViewshed.ENTITY) entity", error: error)
        }
    }
    
    
    func deleteObserver(observer: ObserverEntity) {
        managedContext.deleteObject(observer)
        saveContext(managedContext)
    }
    
    
    func addObservers(addObservers: [Observer]) {
        let entity = NSEntityDescription.entityForName(FogViewshed.ENTITY, inManagedObjectContext: managedContext)
        let managedObject = NSManagedObject(entity: entity!, insertIntoManagedObjectContext:managedContext)
        
        for observer in addObservers {
            managedObject.setValue(observer.algorithm.rawValue, forKey: FogViewshed.ALGORITHM)
            managedObject.setValue(observer.name, forKey: FogViewshed.NAME)
            managedObject.setValue(observer.xCoord, forKey: FogViewshed.XCOORD)
            managedObject.setValue(observer.yCoord, forKey: FogViewshed.YCOORD)
            managedObject.setValue(observer.elevation, forKey: FogViewshed.ELEVATION)
            managedObject.setValue(observer.getRadius(), forKey: FogViewshed.RADIUS)
            managedObject.setValue(observer.coordinate.latitude, forKey: FogViewshed.LATITUDE)
            managedObject.setValue(observer.coordinate.longitude, forKey: FogViewshed.LONGITUDE)
            
            saveContext(managedContext)
        }
    }
    
    
    func addObserver(observer: Observer) {
        let managedObject = NSEntityDescription.insertNewObjectForEntityForName(FogViewshed.ENTITY, inManagedObjectContext: managedContext) as NSManagedObject
        
        managedObject.setValue(observer.algorithm.rawValue, forKey: FogViewshed.ALGORITHM)
        managedObject.setValue(observer.name, forKey: FogViewshed.NAME)
        managedObject.setValue(observer.xCoord, forKey: FogViewshed.XCOORD)
        managedObject.setValue(observer.yCoord, forKey: FogViewshed.YCOORD)
        managedObject.setValue(observer.elevation, forKey: FogViewshed.ELEVATION)
        managedObject.setValue(observer.getRadius(), forKey: FogViewshed.RADIUS)
        managedObject.setValue(observer.coordinate.latitude, forKey: FogViewshed.LATITUDE)
        managedObject.setValue(observer.coordinate.longitude, forKey: FogViewshed.LONGITUDE)
        
        saveContext(managedContext)
    }
    
    
    func saveContext(managedContext: NSManagedObjectContext) {
        do {
            try managedContext.save()
        } catch let error as NSError {
            logError("Error saving \(FogViewshed.ENTITY) entity", error: error)
        }
    }
    
    
    func logError(message: String, error: NSError?) {
        print(message + " \(error): \(error?.userInfo)")
    }
    
    
    func getObservers()-> [ObserverEntity] {
        let fetchRequest = NSFetchRequest(entityName: "Observer")
        fetchRequest.returnsObjectsAsFaults = false
        do {
            let fetchResults = try managedContext.executeFetchRequest(fetchRequest) as? [ObserverEntity]

            if let _ = fetchResults {
                observers = fetchResults!
            }
            
        } catch let error as NSError {
            logError("Error fetching \(FogViewshed.ENTITY) entity", error: error)
        }
        return observers
    }
    
    
}
