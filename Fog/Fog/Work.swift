//
//  Work.swift
//  FogMachine
//
//  Created by Chris Wasko on 11/30/15.
//  Copyright © 2015 NGA. All rights reserved.
//

import Foundation


public class Work: MPCSerializable {
    
    
    public var mpcSerialized : NSData {
        let result = NSKeyedArchiver.archivedDataWithRootObject([])
        
        return result
    }
    
    
    public init () {
    }
    
    
    public required init (mpcSerialized: NSData) {
    }
    
}
