//
//  Observer.swift
//  FogMachineSearch
//
//  Created by Chris Wasko on 11/16/15.
//  Copyright © 2015 NGA. All rights reserved.
//

import Foundation

class Observer: NSObject {
    var name: String
    // 0,0 is top left for x, y
    //1200, 1 is bottom left for x, y
    var x:Int
    var y:Int
    var height:Int
    var radius:Int
    
    init(name: String, x: Int, y: Int, height: Int, radius: Int) {
        self.name = name
        self.x = x
        self.y = y
        self.height = height
        self.radius = radius
    }

}
