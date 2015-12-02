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
    
    
    let viewshedResult: [[Int]]
    
    
    var mpcSerialized : NSData {
        let result = NSKeyedArchiver.archivedDataWithRootObject(
            [FogViewshed.VIEWSHED_RESULT: viewshedResult])
        
        return result
    }
    
    
    init (viewshedResult: [[Int]]) {
        self.viewshedResult = viewshedResult
    }
    
    
    required init (mpcSerialized: NSData) {
        let dict = NSKeyedUnarchiver.unarchiveObjectWithData(mpcSerialized) as! [String: NSObject]
        viewshedResult = dict[FogViewshed.VIEWSHED_RESULT] as! [[Int]]
    }

}

