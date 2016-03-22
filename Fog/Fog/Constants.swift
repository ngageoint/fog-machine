//
//  Constants.swift
//  FogMachine
//
//  Created by Chris Wasko on 11/13/15.
//  Copyright © 2015 NGA. All rights reserved.
//

import Foundation


public struct Fog {
    // Service type can contain only ASCII lowercase letters, numbers, and hyphens. 
    // It must be a unique string, at most 15 characters long
    // Note: Devices will only connect to other devices with the same serviceType value.
    static let SERVICE_TYPE = "fog-machine"
    public static let METRICS = "metrics"
}

public struct Metric {
    public static let START = "start"
    public static let END = "end"
    public static let ELAPSED = "elapsed"
}