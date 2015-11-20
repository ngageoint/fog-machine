//
//  ViewshedWork.swift
//  FogMachineSearch
//
//  Created by Chris Wasko on 11/19/15.
//  Copyright © 2015 NGA. All rights reserved.
//

import Foundation

class ViewshedWork: MPCSerializable {
    
    let numberOfQuadrants: String
    let whichQuadrant: String
    let viewshedResult: String
    
    let assignedTo: String
    let searchInitiator: String
    
    var mpcSerialized : NSData {
        return NSKeyedArchiver.archivedDataWithRootObject(
            [FogViewshed.NUMBER_OF_QUADRANTS: numberOfQuadrants,
                FogViewshed.WHICH_QUADRANT: whichQuadrant,
                FogViewshed.VIEWSHED_RESULT:viewshedResult,
                FogViewshed.ASSIGNED_TO: assignedTo,
                FogViewshed.SEARCH_INITIATOR: searchInitiator])
    }
    
    init (numberOfQuadrants: String, whichQuadrant: String, viewshedResult: String, assignedTo: String, searchInitiator: String) {
        self.numberOfQuadrants = numberOfQuadrants
        self.whichQuadrant = whichQuadrant
        self.viewshedResult = viewshedResult
        self.assignedTo = assignedTo
        self.searchInitiator = searchInitiator
    }
    
    required init (mpcSerialized: NSData) {
        let dict = NSKeyedUnarchiver.unarchiveObjectWithData(mpcSerialized) as! [String: String]
//        numberOfQuadrants = Int(dict[FogViewshed.NUMBER_OF_QUADRANTS]! as! String)!
//        whichQuadrant = Int(dict[FogViewshed.WHICH_QUADRANT]! as! String)!
//        viewshedResult = dict[FogViewshed.VIEWSHED_RESULT]! as! [[Int]]
        numberOfQuadrants = dict[FogViewshed.NUMBER_OF_QUADRANTS]!
        whichQuadrant = dict[FogViewshed.WHICH_QUADRANT]!
        viewshedResult = dict[FogViewshed.VIEWSHED_RESULT]!
        assignedTo = dict[FogViewshed.ASSIGNED_TO]!
        searchInitiator = dict[FogViewshed.SEARCH_INITIATOR]!
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
