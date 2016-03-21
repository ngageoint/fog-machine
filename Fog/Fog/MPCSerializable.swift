//
//  MPCSerializable.swift
//  Fog
//
//  Created by Chris Wasko on 3/18/16.
//  Copyright © 2016 NGA. All rights reserved.
//

import Foundation


public protocol MPCSerializable {
    var mpcSerialized: NSData { get }
    init(mpcSerialized: NSData)
}
