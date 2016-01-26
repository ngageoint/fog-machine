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
    var xCoord:Int
    var yCoord:Int
    var elevation:Int
    var radius:Int
    var coordinate: CLLocationCoordinate2D
    var algorithm: ViewshedAlgorithm

    
    
    init(name: String, xCoord: Int, yCoord: Int, elevation: Int, radius: Int, coordinate: CLLocationCoordinate2D, algorithm: ViewshedAlgorithm = ViewshedAlgorithm.FranklinRay) {
        self.name = name
        self.xCoord = xCoord
        self.yCoord = yCoord
        self.elevation = elevation
        self.radius = radius
        self.coordinate = coordinate
        self.algorithm = algorithm
    }
    
    
    func setHgtCoordinate(newCoordinate: CLLocationCoordinate2D, hgtCoordinate: CLLocationCoordinate2D) {
        self.yCoord = Int((newCoordinate.longitude - hgtCoordinate.longitude) / Srtm3.CELL_SIZE) + 1
        self.xCoord = Srtm3.MAX_SIZE - Int((newCoordinate.latitude - hgtCoordinate.latitude) / Srtm3.CELL_SIZE) + 2

        self.coordinate = CLLocationCoordinate2DMake(
                        hgtCoordinate.latitude + 1 - (Srtm3.CELL_SIZE * Double(xCoord - 1)) + Srtm3.LATITUDE_CELL_CENTER,
                        hgtCoordinate.longitude + (Srtm3.CELL_SIZE * Double(yCoord - 1) + Srtm3.LONGITUDE_CELL_CENTER))
        
        print("xCoord: \(xCoord) yCoord: \(yCoord) lat: \(coordinate.latitude) lon: \(coordinate.longitude) ")
    }
    
    
    func getObserverLocation() -> CLLocationCoordinate2D {
            return coordinate
    }

}