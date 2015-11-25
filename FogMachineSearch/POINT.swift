//
//  ObserverPoint.swift
//  Viewshed
//
//  Created by Ram Subramaniam on 11/12/15.
//  Copyright © 2015 Ram Subramaniam. All rights reserved.
//

import Foundation

public class POINT: NSObject {
    
    var xCoor: Int = 0
    var yCoor: Int = 0
    
    
    init(x :Int, y: Int) {
        self.xCoor = x
        self.yCoor = y
    }
    
    public func getXCoor() -> Int {
        return self.xCoor
    }
    
    public func getYCoor() -> Int {
        return self.yCoor
    }
    
    //Calculates the euclidean distance (distance between two points in Euclidean space) to another point in 2D space.
    //to Other point
    // return Distance between this point and <tt>to</tt>
    public func calcDistance(to:POINT) -> Double {
        // distance between this (observer) point and the "to point"
        let distX: Double = Double (self.getXCoor() - to.getXCoor())
        let distY: Double = Double (self.getYCoor() - to.getYCoor())
        return sqrt((distX*distX) + (distY*distY))
    }
   
}
