//
//  Work.swift
//  FogMachineSearch
//
//  Created by Tyler Burgett on 8/12/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

import Foundation

struct Work: MPCSerializable {
    let lowerBound: String
    let upperBound: String
    let searchTerm: String
    let assignedTo: String
    let searchResults: String
    let searchInitiator: String
    
    var mpcSerialized : NSData {
        return NSKeyedArchiver.archivedDataWithRootObject([FogConstants.LowerBoundKey: lowerBound, FogConstants.UpperBoundKey: upperBound, FogConstants.SearchTermKey: searchTerm, FogConstants.AssignedToKey: assignedTo, FogConstants.SearchResultsKey: searchResults, FogConstants.SearchInitiatorKey: searchInitiator])
    }
    
    init (lowerBound: String, upperBound: String, searchTerm: String, assignedTo: String, searchResults: String, searchInitiator: String) {
        self.lowerBound = lowerBound
        self.upperBound = upperBound
        self.searchTerm = searchTerm
        self.assignedTo = assignedTo
        self.searchResults = searchResults
        self.searchInitiator = searchInitiator
    }
    
    init (mpcSerialized: NSData) {
        let dict = NSKeyedUnarchiver.unarchiveObjectWithData(mpcSerialized) as! [String: String]
        lowerBound = dict[FogConstants.LowerBoundKey]!
        upperBound = dict[FogConstants.UpperBoundKey]!
        searchTerm = dict[FogConstants.SearchTermKey]!
        assignedTo = dict[FogConstants.AssignedToKey]!
        searchResults = dict[FogConstants.SearchResultsKey]!
        searchInitiator = dict[FogConstants.SearchInitiatorKey]!
    }
}


struct WorkArray: MPCSerializable {
    let array: Array<Work>
    
    var mpcSerialized: NSData {
        return NSKeyedArchiver.archivedDataWithRootObject(array.map { $0.mpcSerialized })
    }
    
    init(array: Array<Work>) {
        self.array = array
    }
    
    init(mpcSerialized: NSData) {
        let dataArray = NSKeyedUnarchiver.unarchiveObjectWithData(mpcSerialized) as! [NSData]
        array = dataArray.map { return Work(mpcSerialized: $0) }
    }
}
