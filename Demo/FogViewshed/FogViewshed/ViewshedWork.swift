//
//  ViewshedWork.swift
//  FogMachine
//
//  Created by Chris Wasko on 11/19/15.
//  Copyright © 2015 NGA. All rights reserved.
//

import Foundation
import MapKit
import Fog

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
    let algorithm: Int
    
    
    override var mpcSerialized : NSData {
        let metricsData = encodeDictionary(metrics)
        let result = NSKeyedArchiver.archivedDataWithRootObject(
            [FogViewshed.NUMBER_OF_QUADRANTS: numberOfQuadrants,
                FogViewshed.WHICH_QUADRANT: whichQuadrant,
                //FogViewshed.OBSERVER: observer,
                FogViewshed.NAME: name,
                FogViewshed.XCOORD: xCoord,
                FogViewshed.YCOORD: yCoord,
                FogViewshed.ELEVATION: elevation,
                FogViewshed.RADIUS: radius,
                FogViewshed.LATITUDE: latitude,
                FogViewshed.LONGITUDE: longitude,
                FogViewshed.ALGORITHM: algorithm,
                Fog.METRICS: metricsData])
        
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
        self.radius = observer.getRadius()
        self.latitude = observer.coordinate.latitude
        self.longitude = observer.coordinate.longitude
        self.algorithm = observer.algorithm.rawValue
        super.init()
    }
    
    
    func getObserver() -> Observer {
        return Observer(name: name, xCoord: xCoord, yCoord: yCoord, elevation: elevation, radius: radius, coordinate: CLLocationCoordinate2DMake(latitude, longitude))
    }
    
    
    required init (mpcSerialized: NSData) {
        let workData = NSKeyedUnarchiver.unarchiveObjectWithData(mpcSerialized) as! [String: NSObject]
        numberOfQuadrants = workData[FogViewshed.NUMBER_OF_QUADRANTS] as! Int
        whichQuadrant = workData[FogViewshed.WHICH_QUADRANT] as! Int
        //observer = NSKeyedUnarchiver.unarchiveObjectWithData(dict[FogViewshed.OBSERVER] as! NSData) as! Observer
        name = workData[FogViewshed.NAME] as! String
        xCoord = workData[FogViewshed.XCOORD] as! Int
        yCoord = workData[FogViewshed.YCOORD] as! Int
        elevation = workData[FogViewshed.ELEVATION] as! Int
        radius = workData[FogViewshed.RADIUS] as! Int
        latitude = workData[FogViewshed.LATITUDE] as! Double
        longitude = workData[FogViewshed.LONGITUDE] as! Double
        algorithm = workData[FogViewshed.ALGORITHM] as! Int
        super.init(mpcSerialized: mpcSerialized)
    }
}

