//
//  Observer.swift
//  FogMachineSearch
//
//  Created by Chris Wasko on 11/16/15.
//  Copyright © 2015 NGA. All rights reserved.
//

import Foundation
import MapKit

class Observer: NSObject {
    var name: String
    // 0,0 is top left for x, y
    //1200, 1 is bottom left for x, y
    var x:Int
    var y:Int
    var height:Int
    var radius:Int
    var coordinate: CLLocationCoordinate2D
    
    
    init(name: String, x: Int, y: Int, height: Int, radius: Int, coordinate: CLLocationCoordinate2D) {
        self.name = name
        self.x = x
        self.y = y
        self.height = height
        self.radius = radius
        self.coordinate = coordinate
    }
    
    
    func getObserverLocation() -> CLLocationCoordinate2D {
        
        return CLLocationCoordinate2DMake(
            coordinate.latitude + 1 - (Srtm3.CELL_SIZE * Double(x - 1)) + Srtm3.LATITUDE_CELL_CENTER,
            coordinate.longitude + (Srtm3.CELL_SIZE * Double(y - 1) + Srtm3.LONGITUDE_CELL_CENTER)
        )
    }

}