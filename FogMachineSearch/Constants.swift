//
//  Constants.swift
//  FogMachineSearch
//
//  Created by Chris Wasko on 11/13/15.
//  Copyright © 2015 NGA. All rights reserved.
//

import Foundation


struct FogConstants {
    static let LowerBoundKey = "LowerBound"
    static let UpperBoundKey = "UpperBound"
    static let SearchTermKey = "SearchTerm"
    static let AssignedToKey = "AssignedTo"
    static let SearchResultsKey = "SearchResults"
    static let SearchInitiatorKey = "SearchInitiator"
}


struct Hgt {
    static let MAX_SIZE = 1201
    static let CENTER_OFFSET = 0.5
    static let CELL_SIZE = 1.0 / 1201.0
    static let LATITUDE_CELL_CENTER = 3.0 * (Hgt.CELL_SIZE * Hgt.CENTER_OFFSET)
    static let LONGITUDE_CELL_CENTER = Hgt.CELL_SIZE * Hgt.CENTER_OFFSET
    static let DISPLAY_DIAMETER = 100000.0 * 2.0

}