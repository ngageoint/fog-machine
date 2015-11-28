//
//  ViewshedResult.swift
//  FogMachineSearch
//
//  Created by Chris Wasko on 11/24/15.
//  Copyright © 2015 NGA. All rights reserved.
//

import Foundation
import MapKit

class ViewshedResult: MPCSerializable {
    
    
    let viewshedResult: UIImage//[[Int]]
    let assignedTo: String
    let searchInitiator: String
    
    
    var mpcSerialized : NSData {
        let result = NSKeyedArchiver.archivedDataWithRootObject(
            [FogViewshed.VIEWSHED_RESULT: viewshedResult,
                FogViewshed.ASSIGNED_TO: assignedTo,
                FogViewshed.SEARCH_INITIATOR: searchInitiator])
        
        return result
    }
    
    
    init (viewshedResult: UIImage, assignedTo: String, searchInitiator: String) {
        self.viewshedResult = viewshedResult
        self.assignedTo = assignedTo
        self.searchInitiator = searchInitiator
    }
    
    
    required init (mpcSerialized: NSData) {
        let dict = NSKeyedUnarchiver.unarchiveObjectWithData(mpcSerialized) as! [String: NSObject]
        viewshedResult = dict[FogViewshed.VIEWSHED_RESULT] as! UIImage//[[Int]]
        assignedTo = dict[FogViewshed.ASSIGNED_TO] as! String
        searchInitiator = dict[FogViewshed.SEARCH_INITIATOR] as! String
    }
}

