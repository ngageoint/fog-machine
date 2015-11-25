//
//  DEMData.swift
//  Viewshed
//
//  Created by Ram Subramaniam on 11/12/15.
//  Copyright © 2015 Ram Subramaniam. All rights reserved.
//

import Foundation

public class DEMData  {
    
    private var ncols: Int = 0
    private var nrows: Int = 0
    private var xllcorner: Int = 0
    private var yllcorner: Int = 0
    private var cellsize: Int = 0
    private var nodata: Double = 0.0
    var noDataValue: Double = 0.0
    //public static var DEFAULT_INPUT_DATA_TYPE_SRTM = "SRTM"
    
    var demData = [[Int]](count:Srtm3.MAX_SIZE, repeatedValue:[Int](count:Srtm3.MAX_SIZE, repeatedValue:0))
    
    init(demMatrix: [[Int]])  {
        self.demData = demMatrix
        self.ncols = 0
        self.nrows = 0
        self.xllcorner = 0
        self.yllcorner = 0
        self.cellsize = 0
        self.nodata = 0
        self.noDataValue = 0.0
    }
   
    public func getDem2DMatrix() ->[[Int]] {
        return demData
    }
    public func getNcols() ->Int {
        return ncols
    }
    
    public func getNrows()  ->Int {
        return nrows
    }
    
    public func getXllcorner() ->Int {
        return xllcorner
    }
    
    public func getYllcorner()  ->Int {
        return yllcorner
    }
    
    public func getCellsize()  ->Int {
        return cellsize
    }
    
    public func getNodata() ->Double {
        return nodata
    }
    
    public func getHeight(x: Int, y: Int) ->Int {
        return demData[x][y]
    }
    
    public func getHeightedPoint(xTemp: Int, yTemp: Int) ->ElevationPoint {
        let hTemp: Int =  self.getHeight (yTemp, y: xTemp)
        let elevPoint :ElevationPoint =  ElevationPoint(x: xTemp, y: yTemp, h: Double(hTemp))
        return elevPoint
    }
    
    public  func getHeightedPoint(p: POINT) ->ElevationPoint {
        let xTemp: Int = p.getXCoor()
        let yTemp: Int = p.getYCoor()
        let elevPoint :ElevationPoint =  self.getHeightedPoint(xTemp, yTemp: yTemp)
        return elevPoint
    }

}