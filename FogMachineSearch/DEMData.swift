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
    //private var demFileName: String
    var noDataValue: Double = 0.0
    //public static var DEFAULT_INPUT_DATA_TYPE_SRTM = "SRTM"
    
    //private var demData: [[Double]] = []
    //var demData = [[Double]](count:Srtm3.MAX_SIZE, repeatedValue:[Double](count:Srtm3.MAX_SIZE, repeatedValue:0))
    var demData = Array<Array<Double>>()
    
    init(demMatrix: [[Int]])  {
       /*
        for x in demMatrix {
            for y in x {
                let test: Int = y
                self.demData[x][y] = Double(test)
            }
        }*/
        for column in demMatrix {
            var columnArray = Array<Double>()
            for rowVal in column {
                columnArray.append(Double(rowVal))
            }
            self.demData.append(columnArray)
        }

        self.ncols = 0
        self.nrows = 0
        self.xllcorner = 0
        self.yllcorner = 0
        self.cellsize = 0
        self.nodata = 0
        self.noDataValue = 0.0
    }
    
    /*
    init(fileNamePath: String)  {
    self.demFileName = fileNamePath
    self.readDEMDataFile(self.demFileName)
    }
    */
    
    
    public func readDEMDataFile(fileName: String)  {
        ncols = 0;nrows=0;xllcorner=0;yllcorner=0;cellsize=0
        
        var lineCounter :Int
        lineCounter = 0
        if let input = NSFileHandle(forReadingAtPath: fileName) {
            let scanner = StreamScanner(source: input, delimiters: NSCharacterSet(charactersInString: ":\n"))
            
            while let line: String = scanner.read()  {
                //print("line:\t\(line)")
                let dataAfterSplit = line.characters.split{$0 == " "}.map(String.init)
                if (dataAfterSplit[0].hasPrefix("ncols")) {
                    var temp:String
                    temp = dataAfterSplit[1].stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "\r"))
                    ncols = Int(temp)!
                    print("ncols: \t\(ncols)")
                }
                else if (dataAfterSplit[0].hasPrefix("nrows")) {
                    var temp:String
                    temp = dataAfterSplit[1].stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "\r"))
                    nrows = Int(temp)!
                    print("nrows: \t\(nrows)")
                }
                else if (dataAfterSplit[0].hasPrefix("xllcorner")) {
                    var temp:String
                    temp = dataAfterSplit[1].stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "\r"))
                    xllcorner = Int(temp)!
                    print("xllcorner: \t\(xllcorner)")
                }
                else if (dataAfterSplit[0].hasPrefix("yllcorner")) {
                    var temp:String
                    temp = dataAfterSplit[1].stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "\r"))
                    yllcorner = Int(temp)!
                    print("yllcorner: \t\(yllcorner)")
                }
                else if (dataAfterSplit[0].hasPrefix("NODATA_value")) {
                    var temp:String
                    temp = dataAfterSplit[1].stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "\r"))
                    noDataValue = Double(temp)!
                    print("NODATA_value: \t\(noDataValue)")
                }
                else if (dataAfterSplit[0].hasPrefix("cellsize")) {
                    var temp:String
                    temp = dataAfterSplit[1].stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "\r"))
                    cellsize = Int(temp)!
                    print("cellsize: \t\(cellsize)")
                    demData = [[Double]](count:nrows , repeatedValue:[Double](count:ncols, repeatedValue:0))
                } else {
                    
                    var colCounter : Int
                    colCounter = 0
                    for cellValue in dataAfterSplit {
                        if cellValue != "\r" {
                            let myDouble : Double = NSString(string: cellValue).doubleValue
                            demData[lineCounter][colCounter] = myDouble
                            colCounter++
                        }
                    }
                    lineCounter++
                }
            }
        }
    }
    
    public func getDem2DMatrix() ->[[Double]] {
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
    
    
    public func getHeight(x: Int, y: Int) ->Double {
        return demData[x][y]
    }
    
    public func getHeightedPoint(xTemp: Int, yTemp: Int) ->ElevationPoint {
        let hTemp: Double =  self.getHeight (yTemp, y: xTemp)
        let elevPoint :ElevationPoint =  ElevationPoint(x: xTemp, y: yTemp, h: hTemp)
        
        return elevPoint
    }
    
    public  func getHeightedPoint(p: POINT) ->ElevationPoint {
        let xTemp1: Int = p.getXCoor()
        let yTemp1: Int = p.getYCoor()
        let elevPoint :ElevationPoint =  self.getHeightedPoint(xTemp1, yTemp: yTemp1)
        return elevPoint
    }

}