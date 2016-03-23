//
//  SquarePerimeter.swift
//  FogViewshed
//
//  Created by Chris Wasko on 3/23/16.
//  Copyright © 2016 NGA. All rights reserved.
//

import Foundation


class SquarePerimeter {
    
    // Returns an array of tuple (x,y) for the perimeter of the region based on the observer point and the radius
    // Supports single, double, or quadriple phones based on the number of quadrants (1, 2, or 4)
    static func getAnySizedPerimeter(inX: Int, inY: Int, radius: Int, numberOfQuadrants: Int, whichQuadrant: Int) -> [(x:Int,y:Int)] {
        //Perimeter goes clockwise from the lower left coordinate
        var perimeter:[(x:Int, y:Int)] = []
        //These can be combined into less for loops, but it's easier to debug when the
        //perimeter goes clockwise from the lower left coordinate
        
        //lower left to top left
        for a in inX - radius ... inX + radius {
            perimeter.append((a, inY - radius))
        }
        //top left to top right (excludes corners)
        for b in inY - radius + 1 ..< inY + radius {
            perimeter.append((inX + radius, b))
        }
        //top right to lower right
        for a in (inX + radius).stride(through: (inX - radius), by: -1) {
            perimeter.append((a, inY + radius))
        }
        //lower right to lower left (excludes corners)
        for b in (inY + radius - 1).stride(to: (inY - radius), by: -1) {
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
            startSection += 1
        }
        
        return resultPerimeter
    }
    
    
    private func displayMatrix(matrix: [[Int]]) {
        for x in matrix.reverse() {
            print("\(x)")
        }
    }
}