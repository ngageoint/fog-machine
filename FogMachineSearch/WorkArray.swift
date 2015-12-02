//
//  WorkArray.swift
//  FogMachineSearch
//
//  Created by Chris Wasko on 11/30/15.
//  Copyright © 2015 NGA. All rights reserved.
//

import Foundation
import UIKit
import MapKit

struct WorkArray<T: Work>: MPCSerializable {
    let array: Array<T>
    
    var mpcSerialized: NSData {
        return NSKeyedArchiver.archivedDataWithRootObject(array.map { $0.mpcSerialized })
    }
    
    init(array: Array<T>) {
        self.array = array
    }
    
    init(mpcSerialized: NSData) {
        let dataArray = NSKeyedUnarchiver.unarchiveObjectWithData(mpcSerialized) as! [NSData]
        array = dataArray.map { return T(mpcSerialized: $0) }
    }
}
