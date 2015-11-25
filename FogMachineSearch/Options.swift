//
//  Options.swift
//  FogMachineSearch
//
//  Created by Ram Subramaniam on 11/25/15.
//  Copyright © 2015 NGA. All rights reserved.
//

import Foundation

class Options {
    
    var viewshedAlgorithmName: Int = 1
    
    class var sharedInstance: Options {
        struct Static {
            static var instance: Options?
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            Static.instance = Options()
        }
        return Static.instance!
    }

}