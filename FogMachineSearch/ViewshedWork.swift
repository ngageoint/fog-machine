//
//  ViewshedWork.swift
//  FogMachineSearch
//
//  Created by Chris Wasko on 11/19/15.
//  Copyright © 2015 NGA. All rights reserved.
//

import Foundation
import MapKit

class ViewshedWork: Work {
    
    let numberOfQuadrants: Int
    let whichQuadrant: Int
    
    // Observer properties
    let name: String
    let x:Int
    let y:Int
    let height:Int
    let radius:Int
    let latitude: Double
    let longitude: Double
    
    
    override var mpcSerialized : NSData {
        let result = NSKeyedArchiver.archivedDataWithRootObject(
            [FogViewshed.NUMBER_OF_QUADRANTS: numberOfQuadrants,
                FogViewshed.WHICH_QUADRANT: whichQuadrant,
                //FogViewshed.OBSERVER: observer,
                FogViewshed.NAME: name,
                FogViewshed.X: x,
                FogViewshed.Y: y,
                FogViewshed.HEIGHT: height,
                FogViewshed.RADIUS: radius,
                FogViewshed.LATITUDE: latitude,
                FogViewshed.LONGITUDE: longitude])
        
        return result
    }
    

    init (numberOfQuadrants: Int, whichQuadrant: Int, observer: Observer) {
        self.numberOfQuadrants = numberOfQuadrants
        self.whichQuadrant = whichQuadrant
        //self.observer = observer
        self.name = observer.name
        self.x = observer.x
        self.y = observer.y
        self.height = observer.height
        self.radius = observer.radius
        self.latitude = observer.coordinate.latitude
        self.longitude = observer.coordinate.longitude
        super.init()
    }
    
    
    func getObserver() -> Observer {
        return Observer(name: name, x: x, y: y, height: height, radius: radius, coordinate: CLLocationCoordinate2DMake(latitude, longitude))
    }
    
    
    required init (mpcSerialized: NSData) {
        let dict = NSKeyedUnarchiver.unarchiveObjectWithData(mpcSerialized) as! [String: NSObject]
        numberOfQuadrants = dict[FogViewshed.NUMBER_OF_QUADRANTS] as! Int
        whichQuadrant = dict[FogViewshed.WHICH_QUADRANT] as! Int
        //observer = NSKeyedUnarchiver.unarchiveObjectWithData(dict[FogViewshed.OBSERVER] as! NSData) as! Observer
        name = dict[FogViewshed.NAME] as! String
        x = dict[FogViewshed.X] as! Int
        y = dict[FogViewshed.Y] as! Int
        height = dict[FogViewshed.HEIGHT] as! Int
        radius = dict[FogViewshed.RADIUS] as! Int
        latitude = dict[FogViewshed.LATITUDE] as! Double
        longitude = dict[FogViewshed.LONGITUDE] as! Double
        super.init(mpcSerialized: mpcSerialized)
    }
}

