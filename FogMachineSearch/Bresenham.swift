//
//  Bresenham.swift
//  FogMachineSearch
//
//  Created by Chris Wasko on 11/2/15.
//  Copyright © 2015 NGA. All rights reserved.
//

import UIKit

class Bresenham: NSObject {

    
    // Adopted from http://rosettacode.org/wiki/Bitmap/Bresenham's_line_algorithm#C.2B.2B
    internal func line(var x1: Int, var y1: Int, var x2: Int, var y2: Int) -> [(x:Int,y:Int)] {
        //print("\tArguments: x1: \(x1) y1: \(y1) \t x2: \(x2) y2: \(y2)")
        var results:[(x:Int,y:Int)] = []
        let obsX = x1
        let obsY = y1
        let isSteep:Bool = abs(y2-y1) > abs(x2 - x1)

        if(isSteep) {
            swap(&x1, &y1)
            swap(&x2, &y2)
        }
        
        if(x1 > x2) {
            swap(&x1, &x2)
            swap(&y1, &y2)
        }
        //print("\tAfter swap: x1: \(x1) y1: \(y1) \t x2: \(x2) y2: \(y2)")
        
        let dx:Double = Double(x2) - Double(x1)
        let dy:Double = abs(Double(y2)-Double(y1))
        
        var error:Double = dx / 2.0
        let ystep:Int = (y1 < y2) ? 1 : -1
        
        var y:Int = Int(y1)
        let maxX:Int = Int(x2)
        
        //print("\t dx=\(dx) dy=\(dy) error=\(error) ystep=\(ystep) y=\(y) maxX=\(maxX)")
        for (var x:Int = Int(x1); x <= maxX; x++) { //changed from < maxX
            if(isSteep) {
                //print("\tTrue y, x: \(y), \(x)")
                if (x != obsX || y != obsY) {
                    results.append((y, x))
                }
            } else {
                //print("\tFalse x, y: \(x), \(y)")
                if (x != obsX || y != obsY) {
                    results.append((x, y))
                }
            }
            error -= dy
            if(error < 0) {
                y += ystep
                error += dx
            }
        }
        //dump(results)
        return results
        
    }
    
    

    
}
