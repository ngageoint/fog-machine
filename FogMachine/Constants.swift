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
    static let ENTITY = "Observer"
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
    static let XCOORD = "xCoord"
    static let YCOORD = "yCoord"
    static let ELEVATION = "elevation"
    static let RADIUS = "radius"
    static let LATITUDE = "latitude"
    static let LONGITUDE = "longitude"
    
}

//SRTM = Shuttle Radar Topography Mission sampled at three arc-seconds
struct Srtm3 {
    static let MAX_SIZE = 1201
    static let CENTER_OFFSET = 0.5
    static let CELL_SIZE_DENOMINATOR = 1201.0
    static let DISPLAY_DIAMETER = 100000.0 * 1.5
    static let EXTENT_METERS = 90.0

}

// Position in 2x2 grid
enum GridPosition: String {
    case UpperRight = "upperRight",
    UpperLeft = "upperLeft",
    LowerRight = "lowerRight",
    LowerLeft = "lowerLeft"
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

struct SRTM {
    static let DOWNLOAD_SERVER = "https://fogmachine.geointapps.org/version2_1/SRTM3/"
    static let ALTERNATE_DOWNLOAD_SERVERE = "https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/"
    static let REGION_NORTH_AMERICA = "North_America"
    static let REGION_SOUTH_AMERICA = "South_America"
    static let REGION_EURASIA = "Eurasia"
    static let REGION_AFRICA = "Africa"
    static let REGION_AUSTRALIA = "Australia"
    static let REGION_ISLANDS = "Islands"
    
}
