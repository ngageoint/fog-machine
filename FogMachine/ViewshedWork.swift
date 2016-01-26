//
//  ViewshedWork.swift
//  FogMachine
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
    let xCoord:Int
    let yCoord:Int
    let elevation:Int
    let radius:Int
    let latitude: Double
    let longitude: Double
    
    
    override var mpcSerialized : NSData {
        let result = NSKeyedArchiver.archivedDataWithRootObject(
            [FogViewshed.NUMBER_OF_QUADRANTS: numberOfQuadrants,
                FogViewshed.WHICH_QUADRANT: whichQuadrant,
                //FogViewshed.OBSERVER: observer,
                FogViewshed.NAME: name,
                FogViewshed.X: xCoord,
                FogViewshed.Y: yCoord,
                FogViewshed.ELEVATION: elevation,
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
        self.xCoord = observer.xCoord
        self.yCoord = observer.yCoord
        self.elevation = observer.elevation
        self.radius = observer.radius
        self.latitude = observer.coordinate.latitude
        self.longitude = observer.coordinate.longitude
        super.init()
    }
    
    
    func getObserver() -> Observer {
        return Observer(name: name, xCoord: xCoord, yCoord: yCoord, elevation: elevation, radius: radius, coordinate: CLLocationCoordinate2DMake(latitude, longitude))
    }
    
    
    required init (mpcSerialized: NSData) {
        let dict = NSKeyedUnarchiver.unarchiveObjectWithData(mpcSerialized) as! [String: NSObject]
        numberOfQuadrants = dict[FogViewshed.NUMBER_OF_QUADRANTS] as! Int
        whichQuadrant = dict[FogViewshed.WHICH_QUADRANT] as! Int
        //observer = NSKeyedUnarchiver.unarchiveObjectWithData(dict[FogViewshed.OBSERVER] as! NSData) as! Observer
        name = dict[FogViewshed.NAME] as! String
        xCoord = dict[FogViewshed.X] as! Int
        yCoord = dict[FogViewshed.Y] as! Int
        elevation = dict[FogViewshed.ELEVATION] as! Int
        radius = dict[FogViewshed.RADIUS] as! Int
        latitude = dict[FogViewshed.LATITUDE] as! Double
        longitude = dict[FogViewshed.LONGITUDE] as! Double
        super.init(mpcSerialized: mpcSerialized)
    }
}

