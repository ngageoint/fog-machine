//
//  Work.swift
//  FogMachine
//
//  Created by Chris Wasko on 11/30/15.
//  Copyright © 2015 NGA. All rights reserved.
//

import Foundation


class Work: MPCSerializable {
    
   
    var mpcSerialized : NSData {
        let result = NSKeyedArchiver.archivedDataWithRootObject([])
        
        return result
    }

    
    init () {
    }
    
    
    required init (mpcSerialized: NSData) {
    }

}