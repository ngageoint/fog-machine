//
//  Constants.swift
//  FogMachine
//
//  Created by Chris Wasko on 11/13/15.
//  Copyright © 2015 NGA. All rights reserved.
//

import Foundation


struct FogSearch {
    static let LowerBoundKey = "LowerBound"
    static let UpperBoundKey = "UpperBound"
    static let SearchTermKey = "SearchTerm"
    static let AssignedToKey = "AssignedTo"
    static let SearchResultsKey = "SearchResults"
    static let SearchInitiatorKey = "SearchInitiator"
}

enum Event: String {
    case StartSearch = "StartSearch",
    SendSearchResult = "SendSearchResult"
}
