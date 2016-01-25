//
//  Constants.swift
//  FogMachine
//
//  Created by Chris Wasko on 11/13/15.
//  Copyright © 2015 NGA. All rights reserved.
//

import Foundation


struct Fog {
    // Service type can contain only ASCII lowercase letters, numbers, and hyphens. 
    // It must be a unique string, at most 15 characters long
    // Note: Devices will only connect to other devices with the same serviceType value.
    static let SERVICE_TYPE = "fog-machine"
}


struct FogSearch {
    static let LowerBoundKey = "LowerBound"
    static let UpperBoundKey = "UpperBound"
    static let SearchTermKey = "SearchTerm"
    static let AssignedToKey = "AssignedTo"
    static let SearchResultsKey = "SearchResults"
    static let SearchInitiatorKey = "SearchInitiator"
}


struct FogViewshed {
    static let NUMBER_OF_QUADRANTS = "numberOfQuadrants"
    static let WHICH_QUADRANT = "whichQuadrant"
    static let VIEWSHED_RESULT = "viewshedResult"
    //static let OBSERVER = "observer"
    static let ASSIGNED_TO = "assignedTo"
    static let SEARCH_INITIATOR = "searchInitiator"
    
    static let ALGORITHM = "algorithm"
    
    static let NAME = "name"
    static let X = "x"
    static let Y = "y"
    static let HEIGHT = "height"
    static let RADIUS = "radius"
    static let LATITUDE = "latitude"
    static let LONGITUDE = "longitude"
    
}

//SRTM = Shuttle Radar Topography Mission
struct Srtm3 {
    static let MAX_SIZE = 1201
    static let CENTER_OFFSET = 0.5
    static let CELL_SIZE = 1.0 / 1201.0
    static let LATITUDE_CELL_CENTER = 3.0 * (Srtm3.CELL_SIZE * Srtm3.CENTER_OFFSET)
    static let LONGITUDE_CELL_CENTER = Srtm3.CELL_SIZE * Srtm3.CENTER_OFFSET
    static let DISPLAY_DIAMETER = 100000.0 * 1.5

}

enum MapType: Int {
    case Standard = 0
    case Hybrid
    case Satellite
}

enum Event: String {
    case StartSearch = "StartSearch",
    SendSearchResult = "SendSearchResult",
    StartViewshed = "StartViewshed",
    SendViewshedResult = "SendViewshedResult"
}

enum ViewshedAlgorithm: Int {
    case FranklinRay = 0
    case VanKreveld = 1
}
