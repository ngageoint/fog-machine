//
//  Viewshed.swift
//  FogMachine
//
//  Created by Chris Wasko on 11/2/15.
//  Copyright © 2015 NGA. All rights reserved.
//

import UIKit
import MapKit

public class Viewshed: NSObject {
    
    var elevation: [[Int]]
    var obsX: Int
    var obsY: Int
    var obsElevation: Int
    var viewRadius: Int
    
    
    init(elevation: [[Int]], observer: Observer) {
        self.elevation = elevation
        self.obsX = observer.xCoord
        self.obsY = observer.yCoord
        self.obsElevation = observer.elevation
        self.viewRadius = observer.radius
    }
    
   
    //Adopted from section 5.1 http://www.cs.rpi.edu/~cutler/publications/andrade_geoinformatica.pdf
    //        Given a terrain T represented by an n × n elevation matrix M, a point p on T , a radius
    //        of interest r, and a height h above the local terrain for the observer and target, this
    //        algorithm computes the viewshed of p within a distance r of p, as follows:
    public func viewshed() -> [[Int]] {
        
        // Initialize results array as all un-viewable
        var viewshedMatrix = [[Int]](count:Srtm3.MAX_SIZE, repeatedValue:[Int](count:Srtm3.MAX_SIZE, repeatedValue:0))
        
        // 1. Let p’s coordinates be (xp, yp, zp). Then the observer O will be at (xp, yp, zp + h).
        
        // 2. Imagine a square in the plane z = 0 of side 2r × 2r centered on (xp, yp, 0).
        let perimeter:[(x:Int, y:Int)] = getPerimeter(obsX, inY: obsY, radius: viewRadius)
        
        // 3. Iterate through the cells c of the square’s perimeter. Each c has coordinates
        //  (xc, yc, 0), where the corresponding point on the terrain is (xc, yc, zc).
        for (x, y) in perimeter {
            // print("\nCalling Bresenham on x, y: \(x), \(y)")
            
            // (a) For each c, run a straight line in M from (xp, yp, 0) to (xc, yc, 0).
            
            
            // (b) Find the points on that line, perhaps using Bresenham’s algorithm. In order
            //  from p to c, let them be q1 = p, q2, ··· qk−1, qk = c. A potential target Di at qi
            //  will have coordinates (xi, yi, zi + h).
            
            let bresenham = Bresenham()
            let bresResults:[(x:Int, y:Int)] = bresenham.findLine(obsX, y1: obsY, x2: x, y2: y)
            
            
            //  (c) Let mi be the slope of the line from O to Di, that is,
            //   mi = ( zk − zi + p ) / sqrt( (xi − xp)2 + (yi − yp)^2 )
            
            // (d) Let µ be the greatest slope seen so far along this line. Initialize µ = −∞.
            var greatestSlope = -Double.infinity
            
            // e) Iterate along the line from p to c.
            for (x2, y2) in bresResults {
                
                //hgt elevation is 1201 x 1201, so skip anything outside those bounds
                if (x2 > 0 && y2 > 0) && (x2 < Srtm3.MAX_SIZE && y2 < Srtm3.MAX_SIZE) {
                    // print("Finding angle to: x, y: \(x2),   \(y2)")
                    
                    // i. For each point qi, compute mi.
                    let zk:Int = elevation[obsX][obsY]
                    let zi:Int = elevation[x2][y2]
                    
                    // angle = arctan(opposite/adjacent)
                    let opposite = ( zi - (zk + obsElevation) )
                    let adjacent = sqrt( pow(Double(x2 - obsX), 2) + pow(Double(y2 - obsY), 2) )
                    let angle:Double = (Double(opposite)/Double(adjacent)) // for the actual angle use atan()
                    
                    //print("\t\tzk: \(zk) zi: \(zi)   x2: \(x2)  y2: \(y2)    obsX: \(obsX)  obsY:  \(obsY)")
                    //print("\t\t\topposite / adjacent: \(opposite)  \(adjacent)")
                    //print("angle: \(angle) ")
                    
                    
                    // ii. If mi < µ, then mark qi as hidden from O, that is, as not in the viewshed (which is simply a 2r × 2r bitmap).
                    // iii. Otherwise, mark qi as being in the viewshed, and update µ = mi.
                    if (angle < greatestSlope) {
                        //hidden
                        viewshedMatrix[x2 - 1][y2 - 1] = 0 //used -1 for zero based indexing
                    } else {
                        greatestSlope = angle
                        //visible
                        viewshedMatrix[x2 - 1][y2 - 1] = 1 //used -1 for zero based indexing
                    }
                }
                
            }
            
        }
        
        viewshedMatrix[obsX - 1][obsY - 1] = -1 // mark observer cell as unique
        
        return viewshedMatrix
        
    }
    
    
    // Returns an array of tuple (x,y) for the perimeter of the region based on the observer point
    // and the radius
    private func getPerimeter(inX: Int, inY: Int, radius: Int) -> [(x:Int,y:Int)] {
        //let size = (radius * 2 + 1) * 4 - 4
        
        var perimeter:[(x:Int, y:Int)] = []
        
        //These can be combined into less for loops, but it's easier to debug when the
        //perimeter goes clockwise from the lower left coordinate
        
        //lower left to top left
        for(var a = inX - radius; a <= inX + radius; a++) {
            perimeter.append((a, inY - radius))
        }
        
        //top left to top right (excludes corners)
        for(var b = inY - radius + 1; b < inY + radius; b++) {
            perimeter.append((inX + radius, b))
        }
        
        //top right to lower right
        for(var a = inX + radius; a >= inX - radius; a--) {
            perimeter.append((a, inY + radius))
        }
        
        //lower right to lower left (excludes corners)
        for(var b = inY + radius - 1; b > inY - radius; b--) {
            perimeter.append((inX - radius, b))
        }

        //dump(perimeter)
        return perimeter
    }
    
    
    private func displayMatrix(matrix: [[Int]]) {
        for x in matrix.reverse() {
            print("\(x)")
        }
    }
    

}
