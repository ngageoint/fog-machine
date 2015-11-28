//
//  ViewshedWork.swift
//  FogMachineSearch
//
//  Created by Chris Wasko on 11/19/15.
//  Copyright © 2015 NGA. All rights reserved.
//

import Foundation
import MapKit

class ViewshedWork: MPCSerializable {
    
    let numberOfQuadrants: Int
    let whichQuadrant: Int
    let viewshedResult: [[Int]]
    //let observer: Observer
    let assignedTo: String
    let searchInitiator: String
    
    let name: String
    let x:Int
    let y:Int
    let height:Int
    let radius:Int
    let latitude: Double
    let longitude: Double
    
    
    var mpcSerialized : NSData {
        let result = NSKeyedArchiver.archivedDataWithRootObject(
            [FogViewshed.NUMBER_OF_QUADRANTS: numberOfQuadrants,
                FogViewshed.WHICH_QUADRANT: whichQuadrant,
                FogViewshed.VIEWSHED_RESULT: viewshedResult,
                //FogViewshed.OBSERVER: observer,
                FogViewshed.ASSIGNED_TO: assignedTo,
                FogViewshed.SEARCH_INITIATOR: searchInitiator,
                FogViewshed.NAME: name,
                FogViewshed.X: x,
                FogViewshed.Y: y,
                FogViewshed.HEIGHT: height,
                FogViewshed.RADIUS: radius,
                FogViewshed.LATITUDE: latitude,
                FogViewshed.LONGITUDE: longitude])
        
        return result
    }
    
//    init (numberOfQuadrants: Int, whichQuadrant: Int, viewshedResult: String, observer: Observer, assignedTo: String, searchInitiator: String, name: String, x: Int, y: Int, height: Int, radius: Int, latitude: Double, longitude: Double) {
//        self.numberOfQuadrants = numberOfQuadrants
//        self.whichQuadrant = whichQuadrant
//        self.viewshedResult = viewshedResult
//        //self.observer = observer
//        self.assignedTo = assignedTo
//        self.searchInitiator = searchInitiator
//        self.name = name
//        self.x = x
//        self.y = y
//        self.height = height
//        self.radius = radius
//        self.latitude = latitude
//        self.longitude = longitude
//    }
    
    init (numberOfQuadrants: Int, whichQuadrant: Int, viewshedResult: [[Int]], observer: Observer, assignedTo: String, searchInitiator: String) {
        self.numberOfQuadrants = numberOfQuadrants
        self.whichQuadrant = whichQuadrant
        self.viewshedResult = viewshedResult
        //self.observer = observer
        self.assignedTo = assignedTo
        self.searchInitiator = searchInitiator
        self.name = observer.name
        self.x = observer.x
        self.y = observer.y
        self.height = observer.height
        self.radius = observer.radius
        self.latitude = observer.coordinate.latitude
        self.longitude = observer.coordinate.longitude
    }
    
    
    func getObserver() -> Observer {
        return Observer(name: name, x: x, y: y, height: height, radius: radius, coordinate: CLLocationCoordinate2DMake(latitude, longitude))
    }
    
    
    required init (mpcSerialized: NSData) {
        let dict = NSKeyedUnarchiver.unarchiveObjectWithData(mpcSerialized) as! [String: NSObject]
        numberOfQuadrants = dict[FogViewshed.NUMBER_OF_QUADRANTS] as! Int
        whichQuadrant = dict[FogViewshed.WHICH_QUADRANT] as! Int
        viewshedResult = dict[FogViewshed.VIEWSHED_RESULT] as! [[Int]]
        //observer = NSKeyedUnarchiver.unarchiveObjectWithData(dict[FogViewshed.OBSERVER] as! NSData) as! Observer
        assignedTo = dict[FogViewshed.ASSIGNED_TO] as! String
        searchInitiator = dict[FogViewshed.SEARCH_INITIATOR] as! String
        name = dict[FogViewshed.NAME] as! String
        x = dict[FogViewshed.X] as! Int
        y = dict[FogViewshed.Y] as! Int
        height = dict[FogViewshed.HEIGHT] as! Int
        radius = dict[FogViewshed.RADIUS] as! Int
        latitude = dict[FogViewshed.LATITUDE] as! Double
        longitude = dict[FogViewshed.LONGITUDE] as! Double
    }
}


struct ViewshedWorkArray: MPCSerializable {
    let array: Array<ViewshedWork>
    
    var mpcSerialized: NSData {
        return NSKeyedArchiver.archivedDataWithRootObject(array.map { $0.mpcSerialized })
    }
    
    init(array: Array<ViewshedWork>) {
        self.array = array
    }
    
    init(mpcSerialized: NSData) {
        let dataArray = NSKeyedUnarchiver.unarchiveObjectWithData(mpcSerialized) as! [NSData]
        array = dataArray.map { return ViewshedWork(mpcSerialized: $0) }
    }
}
