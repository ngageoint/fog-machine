//
//  ViewshedFog.swift
//  FogMachine
//
//  Created by Chris Wasko on 11/18/15.
//  Copyright © 2015 NGA. All rights reserved.
//

import UIKit
import MapKit

public class ViewshedFog: NSObject {
    
    var elevation: [[Int]]
    var obsX: Int
    var obsY: Int
    var obsElevation: Int
    var viewRadius: Int
    var numberOfQuadrants: Int
    var whichQuadrant: Int
    
    
    init(elevation: [[Int]], observer: Observer, numberOfQuadrants: Int, whichQuadrant: Int) {
        self.elevation = elevation
        self.obsX = observer.xCoord
        self.obsY = observer.yCoord
        self.obsElevation = observer.elevation
        self.viewRadius = observer.radius
        self.numberOfQuadrants = numberOfQuadrants
        self.whichQuadrant = whichQuadrant
    }
    
    
    public func viewshedParallel(maxSize: Int = Srtm3.MAX_SIZE) -> [[Int]] {
        
        var viewshedMatrix = [[Int]](count:maxSize, repeatedValue:[Int](count:maxSize, repeatedValue:0))
        
        let perimeter:[(x:Int, y:Int)] = getAnySizedPerimeter(obsX, inY: obsY, radius: viewRadius,
            numberOfQuadrants: numberOfQuadrants, whichQuadrant: whichQuadrant)
        
        for (x, y) in perimeter {
            let bresenham = Bresenham()
            let bresResults:[(x:Int, y:Int)] = bresenham.findLine(obsX, y1: obsY, x2: x, y2: y)
            
            
            var greatestSlope = -Double.infinity
            
            for (x2, y2) in bresResults {
                
                if (x2 > 0 && y2 > 0) && (x2 < maxSize && y2 < maxSize) {
                    let zk:Int = elevation[obsX][obsY]
                    let zi:Int = elevation[x2][y2]
                    
                    let opposite = ( zi - (zk + obsElevation) )
                    let adjacent = sqrt( pow(Double(x2 - obsX), 2) + pow(Double(y2 - obsY), 2) )
                    let angle:Double = (Double(opposite)/Double(adjacent)) // for the actual angle use atan()
                    
                    if (angle < greatestSlope) {
                        //hidden
                        viewshedMatrix[x2 - 1][y2 - 1] = 0
                    } else {
                        greatestSlope = angle
                        //visible
                        viewshedMatrix[x2 - 1][y2 - 1] = 1
                    }
                }
                
            }
            
        }
        
        viewshedMatrix[obsX - 1][obsY - 1] = -1 // mark observer cell as unique
        
        return viewshedMatrix
        
    }
    
    
    // Returns an array of tuple (x,y) for the perimeter of the region based on the observer point and the radius
    // Supports single, double, or quadriple phones based on the number of quadrants (1, 2, or 4)
    private func getAnySizedPerimeter(inX: Int, inY: Int, radius: Int, numberOfQuadrants: Int, whichQuadrant: Int) -> [(x:Int,y:Int)] {
        //Perimeter goes clockwise from the lower left coordinate
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
        
        let size = (radius * 2 + 1) * 4 - 4
        let sectionSize = size / numberOfQuadrants
        var startSection = sectionSize * (whichQuadrant - 1)
        if whichQuadrant == 1 {
            startSection = 0
        }
        var endSection = sectionSize * whichQuadrant
        if endSection > size {
            endSection = perimeter.count
        }

        //print("numberOfQuadrants: \(numberOfQuadrants)  size: \(size) sectionSize: \(sectionSize) startSection: \(startSection) endSection: \(endSection) whichQuadrant: \(whichQuadrant)")

        var resultPerimeter: [(x:Int, y:Int)] = []
        
        while (startSection < endSection) {
            resultPerimeter.append(perimeter[startSection])
            startSection++
        }
        
        return resultPerimeter
    }
    

    private func displayMatrix(matrix: [[Int]]) {
        for x in matrix.reverse() {
            print("\(x)")
        }
    }
    
    
}
