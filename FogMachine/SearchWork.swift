//
//  Work.swift
//  FogMachine
//
//  Created by Tyler Burgett on 8/12/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

import Foundation

struct SearchWork: MPCSerializable {
    let lowerBound: String
    let upperBound: String
    let searchTerm: String
    let assignedTo: String
    let searchResults: String
    let searchInitiator: String
    
    var mpcSerialized : NSData {
        return NSKeyedArchiver.archivedDataWithRootObject([FogSearch.LowerBoundKey: lowerBound, FogSearch.UpperBoundKey: upperBound, FogSearch.SearchTermKey: searchTerm, FogSearch.AssignedToKey: assignedTo, FogSearch.SearchResultsKey: searchResults, FogSearch.SearchInitiatorKey: searchInitiator])
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
        lowerBound = dict[FogSearch.LowerBoundKey]!
        upperBound = dict[FogSearch.UpperBoundKey]!
        searchTerm = dict[FogSearch.SearchTermKey]!
        assignedTo = dict[FogSearch.AssignedToKey]!
        searchResults = dict[FogSearch.SearchResultsKey]!
        searchInitiator = dict[FogSearch.SearchInitiatorKey]!
    }
}


struct SearchWorkArray: MPCSerializable {
    let array: Array<SearchWork>
    
    var mpcSerialized: NSData {
        return NSKeyedArchiver.archivedDataWithRootObject(array.map { $0.mpcSerialized })
    }
    
    init(array: Array<SearchWork>) {
        self.array = array
    }
    
    init(mpcSerialized: NSData) {
        let dataArray = NSKeyedUnarchiver.unarchiveObjectWithData(mpcSerialized) as! [NSData]
        array = dataArray.map { return SearchWork(mpcSerialized: $0) }
    }
}
