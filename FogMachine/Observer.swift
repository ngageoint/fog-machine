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
    private var radius:Int
    var coordinate: CLLocationCoordinate2D
    var algorithm: ViewshedAlgorithm

    override init() {
        self.name = "Enter Name"
        self.xCoord = 1
        self.yCoord = 1
        self.elevation = 1
        self.radius = 16093 //approximately 10 miles
        self.coordinate = CLLocationCoordinate2DMake(1, 1)
        self.algorithm = ViewshedAlgorithm.FranklinRay
        super.init()
    }
    
    init(name: String, xCoord: Int, yCoord: Int, elevation: Int, radius: Int, coordinate: CLLocationCoordinate2D, algorithm: ViewshedAlgorithm = ViewshedAlgorithm.FranklinRay) {
        self.name = name
        self.xCoord = xCoord
        self.yCoord = yCoord
        self.elevation = elevation
        self.radius = radius
        self.coordinate = coordinate
        self.algorithm = algorithm
    }
    
    //Will generate new xCoord, yCoord, and coordinates based on the passed in values.
    func setNewCoordinates(newCoordinate: CLLocationCoordinate2D) {
        let hgtCoordinate = CLLocationCoordinate2DMake(floor(newCoordinate.latitude), floor(newCoordinate.longitude))
        
        self.yCoord = Int((newCoordinate.longitude - hgtCoordinate.longitude) / Srtm3.CELL_SIZE) + 1
        self.xCoord = Srtm3.MAX_SIZE - Int((newCoordinate.latitude - hgtCoordinate.latitude) / Srtm3.CELL_SIZE) + 2

        self.coordinate = CLLocationCoordinate2DMake(
                        hgtCoordinate.latitude + 1 - (Srtm3.CELL_SIZE * Double(xCoord - 1)) + Srtm3.LATITUDE_CELL_CENTER,
                        hgtCoordinate.longitude + (Srtm3.CELL_SIZE * Double(yCoord - 1) + Srtm3.LONGITUDE_CELL_CENTER))
        
        print("\(xCoord)  \(yCoord)  \(coordinate)")
    }
    
    //Update the xCoord and yCoord based on lat/lon
    func updateXYLocation() {
        let hgtCoordinate = self.getObserversHgtCoordinate()
        self.yCoord = Int((coordinate.longitude - hgtCoordinate.longitude) / Srtm3.CELL_SIZE) + 1
        self.xCoord = Srtm3.MAX_SIZE - Int((coordinate.latitude - hgtCoordinate.latitude) / Srtm3.CELL_SIZE) + 2
    }
    
    //Update the xCoord and yCoord based on passed in HgtGrid lat/lon
    func updateXYLocationForGrid(hgtGrid: HgtGrid) {
        let hgtCoordinate = hgtGrid.upperLeftHgt.getCoordinate()
        self.yCoord = Int((coordinate.longitude - hgtCoordinate.longitude) / Srtm3.CELL_SIZE) + 1
        self.xCoord = Srtm3.MAX_SIZE - Int((coordinate.latitude - hgtCoordinate.latitude) / Srtm3.CELL_SIZE) + 2
    }
    
    
    func getObserverLocation() -> CLLocationCoordinate2D {
            return coordinate
    }
    
    
    func populateEntity(entity: ObserverEntity) {
        entity.name = name
        entity.xCoord = Int16(xCoord)
        entity.yCoord = Int16(yCoord)
        entity.elevation = Int32(elevation)
        entity.radius = Int16(radius)
        entity.latitude = coordinate.latitude
        entity.longitude = coordinate.longitude
        entity.algorithm = Int16(algorithm.rawValue)
    }
    
    
    func getObserversHgtCoordinate() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(floor(coordinate.latitude), floor(coordinate.longitude))
    }

    
    func getRadius() -> Int {
        return self.radius
    }
    
    
    func setRadius(radius: Int) {
        self.radius = radius
    }
    
    
    func getViewshedSrtm3Radius() -> Int {
        return Int(ceil(Double(self.radius) / Srtm3.EXTENT_METERS))
    }
    
}