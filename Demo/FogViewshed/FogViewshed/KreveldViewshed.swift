//
//  KreveldViewshed.swift
//  Viewshed
//
//  Created by Ram Subramaniam on 11/11/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

import Foundation

class KreveldViewshed {
    
    func parallelKreveld(elevationMatrix: [[Int]], observPt: ElevationPoint, radius: Int, numOfPeers: Int, quadrant2Calc: Int) ->[[Int]] {
        let cellsInRadius = getCellsInRadius(observPt.getXCoord(), observerY: observPt.getYCoord(), radius: radius, numOfPeers: numOfPeers, quadrant2Calc: quadrant2Calc)
        let viewshedMatrix = calculateViewshed (cellsInRadius, elevationMatrix: elevationMatrix, observPt: observPt, radius: radius, numQuadrants: numOfPeers, quadrant2Calc: quadrant2Calc)
        
        return viewshedMatrix
    }
    
    
    // create a queue with the dummy KreveldSweepEventNode event with the eventType OTHER...so the total event count in the queue is one more than normal
    private func calculateViewshed (cellsInRadius:[(x:Int, y:Int)], elevationMatrix: [[Int]], observPt: ElevationPoint, radius: Int, numQuadrants: Int, quadrant2Calc: Int) ->[[Int]] {
        var observPt = observPt
        var viewshedMatrix = [[Int]](count:elevationMatrix.count, repeatedValue:[Int](count:elevationMatrix[0].count, repeatedValue:0))
        //let specifiedElevation = observPt.getHeight()
        
        let KreveldEventTypeEnter:Int = 1
        let KreveldEventTypeCenter:Int = 2
        let KreveldEventTypeExit:Int = 3
        let KreveldEventTypeOther:Int = 0 // only be used on creation/initialization
        
        let observerPtHeight = elevationMatrix[observPt.getXCoord()][observPt.getYCoord()]
        // observerPtHeight.height is added with the additional height specified by the user ????
        observPt.height = observerPtHeight + observPt.getHeight()
        
        var kreveldActive: KreveldActiveBTree = KreveldActiveBTree(reference: observPt)
        
        var sweepEventQueue = PriorityQueue(ascending: true, startingValues: [KreveldSweepEventNode(eventType: KreveldEventTypeOther,
            dataElevPoint: observPt, observerViewPt: observPt, angle: calculateAngle(observPt, view: observPt, type: KreveldEventTypeOther), distance: 0.0)])
        
        //  fill the EventList with all points
        var dataCounter: Int = 0
        var isThisObserverPoint: Bool = true
        for (x, y) in cellsInRadius {
            dataCounter += 1
            let elevationAtXandYInt = elevationMatrix[x][y]
            
            
            let elevPointData: ElevationPoint = ElevationPoint (xCoord: x, yCoord: y , h: elevationAtXandYInt)
            if (isThisObserverPoint) {
                if (elevPointData.getXCoord() == observPt.getXCoord() && elevPointData.getYCoord() == observPt.getYCoord()) {
                    isThisObserverPoint = false
                    continue
                }
            }
            let sweepEnterEventList: KreveldSweepEventNode = KreveldSweepEventNode(eventType: 1,
                dataElevPoint: elevPointData, observerViewPt: observPt, angle: calculateAngle(elevPointData, view: observPt, type: 1), distance: calcDistance(elevPointData, observerViewPt: observPt))
            
            let sweepCenterEventList: KreveldSweepEventNode = KreveldSweepEventNode(eventType: 2,
                dataElevPoint: elevPointData, observerViewPt: observPt, angle: calculateAngle(elevPointData, view: observPt, type: 2), distance: calcDistance(elevPointData, observerViewPt: observPt))
            
            let sweepExitEventList: KreveldSweepEventNode = KreveldSweepEventNode(eventType: 3,
                dataElevPoint: elevPointData, observerViewPt: observPt, angle: calculateAngle(elevPointData, view: observPt, type: 3), distance: calcDistance(elevPointData, observerViewPt: observPt))
            
            sweepEventQueue.push(sweepEnterEventList)
            sweepEventQueue.push(sweepExitEventList)
            sweepEventQueue.push(sweepCenterEventList)
        }
        
        let elevPoints: [ElevationPoint] = pointsOnLine(elevationMatrix, viewpoint: observPt, radius: radius, numQuadrants: numQuadrants);
        for elevPoint in elevPoints {
            kreveldActive.insert(elevPoint);
        }
        //print("============================================")
        //print("Observer Points:  Radius : \(radius*90)\t X: \(observPt.getXCoord())\t Y: \(observPt.getYCoord())\t H: \(specifiedElevation)")
        //print("Queue Building Time: \(stopwatch.elapsedTimeString())")
        //var counterEnter: Int = 0
        //var counterCenter: Int = 0
        //var counterExit: Int = 0
        //var visiblePtCounter: Int = 0
        //var eventCounter: Int = 0
        
        while !sweepEventQueue.isEmpty {
            let sweepEvent: KreveldSweepEventNode! = sweepEventQueue.pop()
            
            switch sweepEvent.getEventType() {
            case KreveldEventTypeEnter:
                kreveldActive.insert(sweepEvent.getDataElevPoint())
                //counterEnter++
                //eventCounter++
            case KreveldEventTypeCenter:
                
                if (kreveldActive.isVisible(sweepEvent.getDataElevPoint())) {
                    let x: Int = sweepEvent.getDataElevPoint().getXCoord()
                    let y: Int = sweepEvent.getDataElevPoint().getYCoord()
                    //visiblePtCounter++
                    viewshedMatrix[x][y] = 1
                } else {
                    
                }
                //counterCenter++
               // eventCounter++
            case KreveldEventTypeExit:
                kreveldActive.delete(sweepEvent.getDataElevPoint())
                //counterExit++
                //eventCounter++
            default:
                let _: Int
            }
            
        }
        //print("Total Kreveld Events: \(eventCounter)")
        //print("VISIBLE POINTS: \(visiblePtCounter)")
        //print("Kreveld Processing Time: \(stopwatch.elapsedTimeString())")
        //print("============================================")
        // should return the updated DEM data...
        return viewshedMatrix
    }
    
    // finds out all the elevation points with in the selected radius
    private func getCellsInRadius(observerX: Int, observerY: Int, radius: Int, numOfPeers: Int, quadrant2Calc:Int ) -> [(x:Int,y:Int)] {
        var cellsInRadius:[(x:Int, y:Int)] = []
        
        // get all the points inside the radius (all 4 quadrants)
        if (numOfPeers == 1) {
            for a in (observerX - radius)...(observerX + radius) {
                for b in (observerY - radius)...(observerY + radius) {
                    cellsInRadius.append((a, Int(b)))
                }
            }
        } else if (numOfPeers == 2) { // split into two halves
            
            if (quadrant2Calc == 1) {
                // left of observer - top left
                for a in (observerX - radius)...observerX {
                    for b in (observerY - radius)...observerY {
                        cellsInRadius.append((a, Int(b)))
                    }
                }
                // left of observer - bottom left
                for b in observerY...(observerY + radius) {
                    for a in (observerX - radius)...observerX {
                        cellsInRadius.append((b, Int(a)))
                    }
                }
            } else if (quadrant2Calc == 2) {
                //  right of observer - bottom right
                for a in observerX...(observerX + radius) {
                    for b in observerY...(observerY + radius) {
                        cellsInRadius.append((a, Int(b)))
                    }
                }
                //  right of observer - top right
                for b in observerY...(observerY + radius) {
                    for a in (observerX - radius)...observerX {
                        cellsInRadius.append((a, Int(b)))
                    }
                }
            }
        } else if (numOfPeers == 4 ) {
            if (quadrant2Calc == 1) {
                // left of observer - top left
                for a in (observerX - radius)...observerX {
                    for b in (observerY - radius)...observerY {
                        cellsInRadius.append((a, Int(b)))
                    }
                }
            } else if (quadrant2Calc == 2) {
                // left of observer - bottom left
                for b in observerY...(observerY + radius) {
                    for a in (observerX - radius)...observerX {
                        cellsInRadius.append((b, Int(a)))
                    }
                }
            } else if (quadrant2Calc == 3) {
                // right of observer - bottom right
                for a in observerX...(observerX + radius) {
                    for b in observerY...(observerY + radius) {
                        cellsInRadius.append((a, Int(b)))
                    }
                }
            } else if (quadrant2Calc == 4) {
                //  right of observer - top right
                for b in observerY...(observerY + radius) {
                    for a in (observerX - radius)...observerX {
                        cellsInRadius.append((a, Int(b)))
                    }
                }
            }
        } else if (numOfPeers == 3 || numOfPeers >= 5 ) {
            
            if (quadrant2Calc >= 1) {
                let perimeter:[(x:Int, y:Int)] = SquarePerimeter.getAnySizedPerimeter(observerX, inY:observerY, radius: radius, numberOfQuadrants: numOfPeers, whichQuadrant: quadrant2Calc)
                
                for (x, y) in perimeter {
                    let pointsInLine:[(x:Int, y:Int)] = Bresenham.findLine(observerX, y1: observerY, x2: x, y2: y)
                    cellsInRadius.appendContentsOf(pointsInLine)
                }
            }
        }
        
        return cellsInRadius
    }
    
    // Viewpoint starting point , point of observation
    // return All points that lie to the right of the starting point and have the same y-coordinate
    func pointsOnLine(elevationMatrix:[[Int]], viewpoint: ElevationPoint, radius: Int, numQuadrants: Int) -> [ElevationPoint] {
        let xCoor: Int = viewpoint.getXCoord()
        let yCoor: Int = viewpoint.getYCoord()
        
        var maxXcoor: Int = 0
        var maxYCoor: Int = 0
        var elevPointOnline: [ElevationPoint] = []
        
        if  (numQuadrants == 1) {
            // radius added to this function to prevent sweep line to go beyond the defined radius
            if ((viewpoint.getXCoord() + radius) < elevationMatrix[0].count) {
                maxXcoor = viewpoint.getXCoord() + radius
            }
            let iterateCount: Int = xCoor + 1
            // TODO - verify & make sure its "less than or equal to"
            for i in iterateCount ... maxXcoor {
                let tmp:ElevationPoint = ElevationPoint(xCoord: i, yCoord: viewpoint.getYCoord(), h: elevationMatrix[i][viewpoint.getYCoord()])
                elevPointOnline.append(tmp)
            }
        } else if (numQuadrants == 2) {
            // radius added to this function to prevent sweep line to go beyond the defined radius
            if ((viewpoint.getYCoord() - radius) < elevationMatrix[0].count) {
                maxYCoor = viewpoint.getYCoord() - radius
            }
            let iterateCount: Int = yCoor + 1
            // TODO - verify & make sure its "less than or equal to"
            for i in iterateCount ... maxYCoor {
                let tmp:ElevationPoint = ElevationPoint(xCoord: viewpoint.getXCoord(), yCoord: i, h: elevationMatrix[viewpoint.getXCoord()][i])
                //print("\t\(tmp.getXCoord())\t\(tmp.getYCoord())")
                elevPointOnline.append(tmp)
            }
            
        } else if (numQuadrants == 3) {
            // radius added to this function to prevent sweep line to go beyond the defined radius
            if ((viewpoint.getXCoord() + radius) < elevationMatrix[0].count) {
                maxXcoor = viewpoint.getXCoord() + radius
            }
            let iterateCount: Int = xCoor + 1
            // TODO - verify & make sure its "less than or equal to"
            for i in iterateCount ... maxXcoor {
                let tmp:ElevationPoint = ElevationPoint(xCoord: i, yCoord: viewpoint.getYCoord(), h: elevationMatrix[i][viewpoint.getYCoord()])
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
        let yc: Double = Double (point1.getYCoord())
        let yv: Double =   Double (view.getYCoord())
        
        let xc: Double = Double (point1.getXCoord())
        let xv: Double =   Double (view.getXCoord())
        
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
    
    
    func getCurrentMillis()->Int64{
        return  Int64(NSDate().timeIntervalSince1970 * 1000)
    }
    
}

