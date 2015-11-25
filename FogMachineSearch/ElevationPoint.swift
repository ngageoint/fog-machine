//
//  ElevationPoint.swift
//  Viewshed
//
//  Created by Ram Subramaniam on 11/12/15.
//  Copyright © 2015 Ram Subramaniam. All rights reserved.
//
import Foundation

public class ElevationPoint: POINT {
    
    var height: Double = 0;
   
    override init(x: Int, y: Int) {
        super.init(x: x, y: y)
    }
   
    init(x: Int, y: Int, h: Double) {
        self.height = h
        super.init(x: x, y: y)
    }

    // alternative to the constructor/init ...???
    public func elsevationPoint (x :Int, y: Int, h: Double) -> ElevationPoint {
        self.xCoor = x
        self.yCoor = y
        return self
    }
    
    public func getHeight() -> Double {
        return self.height;
    }
    
    public func equalsPosition (p: POINT) -> Bool {
        if (p.getXCoor() == self.getXCoor() &&  p.getYCoor() == self.getYCoor()) {
            return true
        } else {
            return false
        }
    }
    
    public func calcSlope (to: ElevationPoint) -> Double {
        let localHeight: Double = to.getHeight() - self.getHeight()
        let result: Double = localHeight/calcDistance(to)
        return result
    }

}