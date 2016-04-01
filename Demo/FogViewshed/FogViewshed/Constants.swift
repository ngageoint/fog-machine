//
//  Constants.swift
//  FogMachine
//
//  Created by Chris Wasko on 11/13/15.
//  Copyright © 2015 NGA. All rights reserved.
//

import Foundation
import Fog

struct FogViewshed {
    static let NUMBER_OF_QUADRANTS = "numberOfQuadrants"
    static let WHICH_QUADRANT = "whichQuadrant"
    static let VIEWSHED_RESULT = "viewshedResult"

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
    
    static let ENTITY = "Observer"
    static let METRICS = "ViewshedMetrics"
}

//SRTM = Shuttle Radar Topography Mission sampled at three arc-seconds
struct Srtm3 {
    static let MAX_SIZE = 1201
    static let CENTER_OFFSET = 0.5
    static let CELL_SIZE_DENOMINATOR = 1201.0
    static let DISPLAY_DIAMETER = 100000.0 * 1.5
    static let EXTENT_METERS = 90.0

}

enum MapType: Int {
    case Standard = 0
    case Hybrid
    case Satellite
}

enum Event: String {
    case StartViewshed = "StartViewshed",
    SendViewshedResult = "SendViewshedResult"
}

enum ViewshedAlgorithm: Int {
    case FranklinRay = 0
    case VanKreveld = 1
}

struct Srtm {
    static let DOWNLOAD_SERVER = "https://fogmachine.geointapps.org/version2_1/SRTM3/"
    static let ALTERNATE_DOWNLOAD_SERVER = "https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/"
    static let REGION_NORTH_AMERICA = "North_America"
    static let REGION_SOUTH_AMERICA = "South_America"
    static let REGION_EURASIA = "Eurasia"
    static let REGION_AFRICA = "Africa"
    static let REGION_AUSTRALIA = "Australia"
    static let REGION_ISLANDS = "Islands"
    static let FILE_EXTENSION = ".hgt"
    
}


struct Metric {
    static let WORK = "1: Work Processed"
    static let VIEWSHED = "1.1: Process Viewshed"
    static let OVERLAY = "1.2: Process Overlay"
    struct Data {
        static let READING = "1.1.1: Loading single HGT"
        static let MERGING = "1.1.2: Merging all HGT(s)"
    }

    // Update with the order the metrics will be displayed
    static let OUTPUT_ORDER = [Metric.WORK,
                               Metric.VIEWSHED,
                               Metric.Data.READING,
                               Metric.Data.MERGING,
                               Metric.OVERLAY,
                               Fog.Metric.SEND,
                               Fog.Metric.RECEIVE]
}