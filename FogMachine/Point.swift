//
//  ObserverPoint.swift
//  Viewshed
//
//  Created by Ram Subramaniam on 11/12/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

import Foundation

public class Point: NSObject {
    
    var xCoord: Int = 0
    var yCoord: Int = 0
    
    
    init(xCoord :Int, yCoord: Int) {
        self.xCoord = xCoord
        self.yCoord = yCoord
    }
    
    public func getXCoord() -> Int {
        return self.xCoord
    }
    
    public func getYCoord() -> Int {
        return self.yCoord
    }
    
    //Calculates the euclidean distance (distance between two points in Euclidean space) to another point in 2D space.
    //to Other point
    // return Distance between this point and <tt>to</tt>
    public func calcDistance(to:Point) -> Double {
        // distance between this (observer) point and the "to point"
        let distX: Double = Double (self.getXCoord() - to.getXCoord())
        let distY: Double = Double (self.getYCoord() - to.getYCoord())
        return sqrt((distX*distX) + (distY*distY))
    }
   
}
