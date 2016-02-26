//
//  ObserverEntity.swift
//  FogMachine
//
//  Created by Chris Wasko on 1/27/16.
//  Copyright © 2016 NGA. All rights reserved.
//

import Foundation
import CoreData
import MapKit

@objc(ObserverEntity)
class ObserverEntity: NSManagedObject {
    
    @NSManaged var algorithm: Int16
    @NSManaged var elevation: Int32
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var name: String
    @NSManaged var radius: Int32
    @NSManaged var xCoord: Int16
    @NSManaged var yCoord: Int16
    
    
    func getObserver() -> Observer {
        return Observer(name: name, xCoord: Int(xCoord), yCoord: Int(yCoord), elevation: Int(elevation), radius: Int(radius), coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), algorithm: ViewshedAlgorithm(rawValue: Int(algorithm))!)
    }

}
