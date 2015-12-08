//
//  KreveldViewshed.swift
//  Viewshed
//
//  Created by Ram Subramaniam on 11/11/15.
//  Copyright © 2015 Ram Subramaniam. All rights reserved.
//

import Foundation

class KreveldViewshed {
    
    
    func parallelKreveld(demData: DemData, observPt: ElevationPoint, radius: Int, numOfPeers: Int, quadrant2Calc: Int) ->[[Int]] {
        var viewshedMatrix = [[Int]](count:Srtm3.MAX_SIZE, repeatedValue:[Int](count:Srtm3.MAX_SIZE, repeatedValue:0))
        var cellsInRadius:[(x:Int, y:Int)] = []
        
        cellsInRadius = getCellsInRadius(observPt.getXCoor(), observerY: observPt.getYCoor(), radius: radius, numOfPeers: numOfPeers, quadrant2Calc: quadrant2Calc)
        viewshedMatrix = calculateViewshed (cellsInRadius, demData: demData, observPt: observPt, radius: radius, numQuadrants: numOfPeers, quadrant2Calc: quadrant2Calc)

        //for (x, y) in cellsInRadius {
        //    viewshedMatrix[x][y] = 1
        //}
        
        return viewshedMatrix
    }
    
    
    // create a queue with the dummy KreveldSweepEventNode event with the eventType OTHER...so the total event count in the queue is one more than normal
    private func calculateViewshed (cellsInRadius:[(x:Int, y:Int)], demData: DemData, observPt: ElevationPoint, radius: Int, numQuadrants: Int, quadrant2Calc: Int) ->[[Int]] {
        var viewshedMatrix = [[Int]](count:Srtm3.MAX_SIZE, repeatedValue:[Int](count:Srtm3.MAX_SIZE, repeatedValue:0))
        
        struct Point1 { // Dummy structure TODO: get rid off it
            let x: Int
            let y: Int
        }
        let dummy: Point1 = Point1(x: -1, y: -1);
        
        let startTime: Int64 = getCurrentMillis()
        
        let KreveldEventTypeEnter:Int = 1
        let KreveldEventTypeCenter:Int = 2
        let KreveldEventTypeExit:Int = 3
        let KreveldEventTypeOther:Int = 0 // only be used on creation/initialization
        
        
        let observerPtHeight: ElevationPoint = demData.getHeightedPoint(observPt.getXCoor(), yTemp: observPt.getYCoor())
        // observerPtHeight.height is added with the additional height specified by the user ????
        observPt.height = observerPtHeight.height + observPt.getHeight()
        
        let demDataMatrix: [[Int]] = demData.getDem2DMatrix()
        let kreveldActive: KreveldActiveBTree = KreveldActiveBTree(reference: observPt)
        var sweepEventQueue = PriorityQueue(ascending: true, startingValues: [KreveldSweepEventNode(state: dummy, eventType: KreveldEventTypeOther,
            dataElevPoint: observPt, observerViewPt: observPt, angle: calculateAngle(observPt, view: observPt, type: KreveldEventTypeOther), distance: 0.0)])
        
        //  fill the EventList with all points
        var dataCounter: Int = 0
        
        for (x, y) in cellsInRadius {
            dataCounter++
            //let currQuadrant: Int =  getQuadrant(x, y: y, observX: observPt.getXCoor(), observY: observPt.getYCoor())
            //if currQuadrant == numQuadrants {
            // handle everything in Double .. atleast for now
            let elevationAtXandY:Double = Double(demDataMatrix[x][y])
            
            let elevPointData: ElevationPoint = ElevationPoint (x: x, y: y , h: elevationAtXandY)
            if elevPointData.getXCoor() == observPt.getXCoor() && elevPointData.getYCoor() == observPt.getYCoor() {
            } else {
                let sweepEnterEventList: KreveldSweepEventNode = KreveldSweepEventNode(state: dummy, eventType: 1,
                    dataElevPoint: elevPointData, observerViewPt: observPt, angle: calculateAngle(elevPointData, view: observPt, type: 1), distance: calcDistance(elevPointData, observerViewPt: observPt))
                let sweepExitEventList: KreveldSweepEventNode = KreveldSweepEventNode(state: dummy, eventType: 2,
                    dataElevPoint: elevPointData, observerViewPt: observPt, angle: calculateAngle(elevPointData, view: observPt, type: 2), distance: calcDistance(elevPointData, observerViewPt: observPt))
                let sweepCenterEventList: KreveldSweepEventNode = KreveldSweepEventNode(state: dummy, eventType: 3,
                    dataElevPoint: elevPointData, observerViewPt: observPt, angle: calculateAngle(elevPointData, view: observPt, type: 3), distance: calcDistance(elevPointData, observerViewPt: observPt))
                
                sweepEventQueue.push(sweepEnterEventList)
                sweepEventQueue.push(sweepExitEventList)
                sweepEventQueue.push(sweepCenterEventList)
            }
        }
        
        var currentTime = getCurrentMillis()
        var elapsedTime = currentTime - startTime
        print("Total dataCounter: \(dataCounter)")
        
        let elevPoints: [ElevationPoint] = pointsOnLine(demData, viewpoint: observPt, radius: radius, numQuadrants: numQuadrants);
        for elevPoint in elevPoints {
            kreveldActive.insert(elevPoint);
        }
        
        var counterEnter: Int = 0
        var counterCenter: Int = 0
        var counterExit: Int = 0
        var visiblePtCounter: Int = 0
        var eventCounter: Int = 0
        
        while !sweepEventQueue.isEmpty {
            let sweepEvent: KreveldSweepEventNode! = sweepEventQueue.pop()
            let eventType: Int = sweepEvent.getEventType()
            
            
            switch eventType {
            case KreveldEventTypeEnter:
                kreveldActive.insert(sweepEvent.getDataElevPoint())
                counterEnter++
                eventCounter++
            case KreveldEventTypeCenter:
                if (kreveldActive.isVisible(sweepEvent.getDataElevPoint())) {
                    let x: Int = sweepEvent.getDataElevPoint().getXCoor()
                    let y: Int = sweepEvent.getDataElevPoint().getYCoor()
                    visiblePtCounter++
                    viewshedMatrix[x][y] = 1
                    //print("(\(x), \(y))\t")
                } else {
                    
                }
                counterCenter++
                eventCounter++
            case KreveldEventTypeExit:
                kreveldActive.delete(sweepEvent.getDataElevPoint())
                counterExit++
                eventCounter++
            default:
                let _: Int
            }
        }
        currentTime = getCurrentMillis()
        elapsedTime = currentTime - startTime
        print("Kreveld processing time: \(Double(elapsedTime)) (ms)")
        print("Total Kreveld Events: \(eventCounter)")
        
        //print("ENTER: \(counterEnter)")
        //print("CENTER: \(counterCenter)")
        //print("EXIT: \(counterExit)")
        print("VISIBLE POINTS: \(visiblePtCounter)")
        print("\n")
        
        // should return the updated DEM data...
        return viewshedMatrix
    }
    //Adopted from http://rosettacode.org/wiki/Bitmap/Bresenham's_line_algorithm#Java
    internal func findLine(var x1: Int, var y1: Int, x2: Int, y2: Int) -> [(x:Int,y:Int)] {
        
        var results:[(x:Int,y:Int)] = []
        let obsX = x1
        let obsY = y1
        
        // delta of exact value and rounded value of the dependant variable
        var d = 0;
        
        let dy = abs(y2 - y1);
        let dx = abs(x2 - x1);
        
        let dy2 = (dy << 1); // slope scaling factors to avoid floating
        let dx2 = (dx << 1); // point
        
        let ix = x1 < x2 ? 1 : -1; // increment direction
        let iy = y1 < y2 ? 1 : -1;
        
        if (dy <= dx) {
            for (;;) {
                if (x1 != obsX || y1 != obsY) { // skip the observer point
                    results.append((x1, y1))
                }
                if (x1 == x2) {
                    break;
                }
                x1 += ix;
                d += dy2;
                if (d > dx) {
                    y1 += iy;
                    d -= dx2;
                }
            }
        } else {
            for (;;) {
                if (x1 != obsX || y1 != obsY) { // skip the observer point
                    results.append((x1, y1))
                }
                if (y1 == y2) {
                    break;
                }
                y1 += iy;
                d += dx2;
                if (d > dy) {
                    x1 += ix;
                    d -= dy2;
                }
            }
        }
        return results
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
        
        print("numberOfQuadrants: \(numberOfQuadrants)  size: \(size) sectionSize: \(sectionSize) startSection: \(startSection) endSection: \(endSection) whichQuadrant: \(whichQuadrant)")
        
        var resultPerimeter: [(x:Int, y:Int)] = []
        
        for (startSection; startSection < endSection; startSection++) {
            resultPerimeter.append(perimeter[startSection])
        }
        
        
        return resultPerimeter
    }
    
    // finds out all the elevation points with in the selected radius
    private func getCellsInRadius(observerX: Int, observerY: Int, radius: Int, numOfPeers: Int, quadrant2Calc:Int ) -> [(x:Int,y:Int)] {
        var cellsInRadius:[(x:Int, y:Int)] = []
        
        // get all the points inside the radius (all 4 quadrants)
        if (numOfPeers == 1) {
            for (var a = (observerX - radius); a <= (observerX + radius); a++) {
                for (var b:Int = (observerY - radius); b <= (observerY + radius); b++) {
                    cellsInRadius.append((a, Int(b)))
                }
            }
        } else if (numOfPeers == 2) { // split into two halves
            
            if (quadrant2Calc == 1) {
                // left of observer - top left
                for (var a = (observerX - radius); a <= observerX; a++) {
                    for (var b:Int = (observerY - radius); b <= observerY; b++) {
                        cellsInRadius.append((a, Int(b)))
                    }
                }
                // left of observer - bottom left
                for (var b:Int = observerY; b <= (observerY + radius); b++) {
                    for (var a = (observerX - radius); a <= observerX; a++) {
                        cellsInRadius.append((b, Int(a)))
                    }
                }
            } else if (quadrant2Calc == 2) {
                //  right of observer - bottom right
                for (var a = observerX; a <= (observerX + radius); a++) {
                    for (var b:Int = observerY; b <= (observerY + radius); b++) {
                        cellsInRadius.append((a, Int(b)))
                    }
                }
                //  right of observer - top right
                for (var b:Int = observerY; b <= (observerY + radius); b++) {
                    for (var a = (observerX - radius); a <= observerX; a++) {
                        cellsInRadius.append((a, Int(b)))
                    }
                }
            }
        } else if (numOfPeers == 4 ) {
            if (quadrant2Calc == 1) {
                // left of observer - top left
                for (var a = (observerX - radius); a <= observerX; a++) {
                    for (var b:Int = (observerY - radius); b <= observerY; b++) {
                        cellsInRadius.append((a, Int(b)))
                    }
                }
            } else if (quadrant2Calc == 2) {
                // left of observer - bottom left
                for (var b:Int = observerY; b <= (observerY + radius); b++) {
                    for (var a = (observerX - radius); a <= observerX; a++) {
                        cellsInRadius.append((b, Int(a)))
                    }
                }
            } else if (quadrant2Calc == 3) {
                // right of observer - bottom right
                for (var a = observerX; a <= (observerX + radius); a++) {
                    for (var b:Int = observerY; b <= (observerY + radius); b++) {
                        cellsInRadius.append((a, Int(b)))
                    }
                }
            } else if (quadrant2Calc == 4) {
                //  right of observer - top right
                for (var b:Int = observerY; b <= (observerY + radius); b++) {
                    for (var a = (observerX - radius); a <= observerX; a++) {
                        cellsInRadius.append((a, Int(b)))
                    }
                }
            }
        } else if (numOfPeers == 3 || numOfPeers >= 5 ) {
            
            // parametric euqation of a circle
            if (quadrant2Calc >= 1) {
               let perimeter:[(x:Int, y:Int)] = getAnySizedPerimeter(observerX, inY:observerY, radius: radius, numberOfQuadrants: numOfPeers, whichQuadrant: quadrant2Calc)
                
                for (x, y) in perimeter {
                    let pointsInLine:[(x:Int, y:Int)] = findLine(observerX, y1: observerY, x2: x, y2: y)
                    cellsInRadius.appendContentsOf(pointsInLine)
                }
            }
        }
        //print("\t\(cellsInRadius)")
        return cellsInRadius
    }
    
    // Viewpoint starting point , point of observation
    // return All points that lie to the right of the starting point and have the same y-coordinate
    func pointsOnLine(d: DemData, viewpoint: ElevationPoint, radius: Int, numQuadrants: Int) -> [ElevationPoint] {
        let xCoor: Int = viewpoint.getXCoor()
        let yCoor: Int = viewpoint.getYCoor()
        
        //let maxXcoor: Int = d.getNcols() - 1
        var maxXcoor: Int = 0
        var maxYCoor: Int = 0
        var elevPointOnline: [ElevationPoint] = []
        
        if  (numQuadrants == 1) {
            // radius added to this function to prevent sweep line to go beyond the defined radius
            if ((viewpoint.getXCoor() + radius) < d.getNcols()) {
                maxXcoor = viewpoint.getXCoor() + radius
            }
            let iterateCount: Int = xCoor + 1
            // TODO - verify & make sure its "less than or equal to"
            for var i = iterateCount; i <= maxXcoor; i++ {
                let tmp:ElevationPoint = d.getHeightedPoint(i, yTemp: viewpoint.getYCoor())
                elevPointOnline.append(tmp)
            }
        } else if (numQuadrants == 2) {
            // radius added to this function to prevent sweep line to go beyond the defined radius
            if ((viewpoint.getYCoor() - radius) < d.getNcols()) {
                maxYCoor = viewpoint.getYCoor() - radius
            }
            let iterateCount: Int = yCoor + 1
            // TODO - verify & make sure its "less than or equal to"
            for var i = iterateCount; i <= maxYCoor; i++ {
                let tmp:ElevationPoint = d.getHeightedPoint(viewpoint.getXCoor(), yTemp: i)
                print("\t\(tmp.getXCoor())\t\(tmp.getYCoor())")
                elevPointOnline.append(tmp)
            }
            
        } else if (numQuadrants == 3) {
            // radius added to this function to prevent sweep line to go beyond the defined radius
            if ((viewpoint.getXCoor() + radius) < d.getNcols()) {
                maxXcoor = viewpoint.getXCoor() + radius
            }
            let iterateCount: Int = xCoor + 1
            // TODO - verify & make sure its "less than or equal to"
            for var i = iterateCount; i <= maxXcoor; i++ {
                let tmp:ElevationPoint = d.getHeightedPoint(i, yTemp: viewpoint.getYCoor())
                elevPointOnline.append(tmp)
            }
        } else if (numQuadrants == 4) {
            
        }
        
        
        
        return elevPointOnline
    }
    
    // calculates the angle from the start point to all four corners of a pixel
    // atan2 function automatically calculates the correct angle for each quadrant
    // return Angle between the starting point and cornerstone of a pixel
    func calculateAngle(point1: ElevationPoint, view: ElevationPoint, type: Int) -> Double {
        let yc: Double = Double (point1.getYCoor())
        let yv: Double =   Double (view.getYCoor())
        
        let xc: Double = Double (point1.getXCoor())
        let xv: Double =   Double (view.getXCoor())
        
        let dy: Double =  yc - yv
        let dx:Double = xc - xv
        
        // TODO - verify the calc
        // Pixel has same y - coordinate as the starting point is , the right of it and has event type ENTER
        // hen the corresponding corner of the pixel is retrieved and calculates the angles thereto
        if (dy == 0 && dx > 0 && type == KreveldEventTypeEnter) {
            var angle: Double = atan2(-0.5, dx - 0.5)
            angle += 2 * M_PI
            return angle
            // Pixel has same y - coordinate as the starting point is , the right of it and has event type EXIT
        } else if (dy == 0 && dx > 0 && type == KreveldEventTypeExit) {
            let angle: Double = atan2(+0.5, dx - 0.5)
            return angle
        } else if (type == KreveldEventTypeCenter) {
            var angle: Double = atan2(dy, dx)
            if (angle < 0) {
                angle += 2 * M_PI
            }
            return angle
            // EventType ENTER: four corners as possible candidates
            // compute all four angles to the corners and take the smallest
        } else if (type == KreveldEventTypeEnter) {
            var a1: Double = atan2(dy + 0.5, dx + 0.5)
            if (a1 < 0) {
                a1 += 2 * M_PI
            }
            var a2: Double = atan2(dy - 0.5, dx + 0.5);
            if (a2 < 0) {
                a2 += 2 * M_PI
            }
            var a3: Double = atan2(dy + 0.5, dx - 0.5);
            if (a3 < 0) {
                a3 += 2 * M_PI
            }
            var a4:Double = atan2(dy - 0.5, dx - 0.5);
            if (a4 < 0) {
                a4 += 2 * M_PI
            }
            
            let angle: Double = min(min(a1, a2), min(a3, a4))
            return angle
        } else {
            var a1: Double = atan2(dy + 0.5, dx + 0.5)
            if (a1 < 0) {
                a1 += 2 * M_PI
            }
            var a2: Double = atan2(dy - 0.5, dx + 0.5)
            if (a2 < 0) {
                a2 += 2 * M_PI
            }
            var a3: Double = atan2(dy + 0.5, dx - 0.5)
            if (a3 < 0) {
                a3 += 2 * M_PI
            }
            var a4:Double = atan2(dy - 0.5, dx - 0.5)
            if (a4 < 0) {
                a4 += 2 * M_PI
            }
            
            let angle: Double = max(max(a1, a2), max(a3, a4))
            return angle
        }
    }
    
    // Calculates the euclidean distance (distance between two points in Euclidean space) to another point in 2D space.
    // parameter 'to' Other point
    // return Distance between this point and 'to'
    func calcDistance(dataElevPoint: ElevationPoint, observerViewPt: ElevationPoint) -> Double {
        let tmpRet: Double = observerViewPt.calcDistance(dataElevPoint)
        return tmpRet
    }
    
    // Returns the quadrant where (x,y) is
    // x and y must be non-zero integers
    // TODO : need to be done for the DEM matrix data
    func getQuadrant(x: Int, y: Int, observX: Int, observY: Int) -> Int {
        if (x <= observX && y <= observY) {
            return 1
        } else if (x > observX && y < observY) {
            return 2
        } else if (x < observX && y > observY) {
            return 3
        } else if (x >= observX && y >= observY) {
            return 4
        }
        return 0 // This should never be reached
    }
    
    func getCurrentMillis()->Int64{
        return  Int64(NSDate().timeIntervalSince1970 * 1000)
    }
    
}

