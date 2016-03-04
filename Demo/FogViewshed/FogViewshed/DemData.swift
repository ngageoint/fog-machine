//
//  DemData.swift
//  Viewshed
//
//  Created by Ram Subramaniam on 11/12/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

import Foundation

public struct DemData  {
    
    private var ncols: Int = 0
    private var nrows: Int = 0
    private var nodata: Double = 0.0
    var noDataValue: Double = 0.0
    
    var demData = [[Int]](count:Srtm3.MAX_SIZE, repeatedValue:[Int](count:Srtm3.MAX_SIZE, repeatedValue:0))
    
    init(demMatrix: [[Int]])  {
        self.demData = demMatrix
        self.ncols = 0
        self.nrows = 0
        self.nodata = 0
        self.noDataValue = 0.0
    }
    
    public func getDem2DMatrix() ->[[Int]] {
        return demData
    }
    public func getNcols() ->Int {
        return Srtm3.MAX_SIZE
    }
    
    public func getNrows()  ->Int {
        return Srtm3.MAX_SIZE
    }
    
    public func getNodata() ->Double {
        return nodata
    }
    
    public func getHeight(x: Int, y: Int) ->Int {
        return demData[x][y]
    }
    
    public func getHeightedPoint(xTemp: Int, yTemp: Int) ->ElevationPoint {
        let hTemp: Int =  self.getHeight (yTemp, y: xTemp)
        let elevPoint :ElevationPoint =  ElevationPoint(xCoord: xTemp, yCoord: yTemp, h: hTemp)
        return elevPoint
    }
    
    public  func getHeightedPoint(p: ElevationPoint) ->ElevationPoint {
        let xTemp: Int = p.getXCoord()
        let yTemp: Int = p.getYCoord()
        let elevPoint :ElevationPoint =  self.getHeightedPoint(xTemp, yTemp: yTemp)
        return elevPoint
    }
}
