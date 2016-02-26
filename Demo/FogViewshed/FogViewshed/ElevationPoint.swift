//
//  ElevationPoint.swift
//  Viewshed
//
//  Created by Ram Subramaniam on 11/12/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//
import Foundation

public class ElevationPoint: Point {
    
    var height: Double = 0;
   
    override init(xCoord: Int, yCoord: Int) {
        super.init(xCoord: xCoord, yCoord: yCoord)
    }
   
    init(xCoord: Int, yCoord: Int, h: Double) {
        self.height = h
        super.init(xCoord: xCoord, yCoord: yCoord)
    }

    // alternative to the constructor/init ...???
    public func elsevationPoint (xCoord :Int, yCoord: Int, h: Double) -> ElevationPoint {
        self.xCoord = xCoord
        self.yCoord = yCoord
        return self
    }
    
    public func getHeight() -> Double {
        return self.height;
    }
    
    public func equalsPosition (p: Point) -> Bool {
        if (p.getXCoord() == self.getXCoord() &&  p.getYCoord() == self.getYCoord()) {
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