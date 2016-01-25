//
//  Observer.swift
//  FogMachine
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
    var viewshedAlgorithm: ViewshedAlgorithm

    
    
    init(name: String, x: Int, y: Int, height: Int, radius: Int, coordinate: CLLocationCoordinate2D, viewshedAlgorithm: ViewshedAlgorithm = ViewshedAlgorithm.FranklinRay) {
        self.name = name
        self.x = x
        self.y = y
        self.height = height
        self.radius = radius
        self.coordinate = coordinate
        self.viewshedAlgorithm = viewshedAlgorithm
    }
    
    
    func setHgtCoordinate(newCoordinate: CLLocationCoordinate2D, hgtCoordinate: CLLocationCoordinate2D) {
        self.y = Int((newCoordinate.longitude - hgtCoordinate.longitude) / Srtm3.CELL_SIZE) + 1
        self.x = Srtm3.MAX_SIZE - Int((newCoordinate.latitude - hgtCoordinate.latitude) / Srtm3.CELL_SIZE) + 2

        self.coordinate = CLLocationCoordinate2DMake(
                        hgtCoordinate.latitude + 1 - (Srtm3.CELL_SIZE * Double(x - 1)) + Srtm3.LATITUDE_CELL_CENTER,
                        hgtCoordinate.longitude + (Srtm3.CELL_SIZE * Double(y - 1) + Srtm3.LONGITUDE_CELL_CENTER))
        
        print("x: \(x) y: \(y) lat: \(coordinate.latitude) lon: \(coordinate.longitude) ")
    }
    
    
    func getObserverLocation() -> CLLocationCoordinate2D {
            return coordinate
    }

}