//
//  KreveldViewshedImpl.swift
//  Viewshed
//
//  Created by Ram Subramaniam on 11/11/15.
//  Copyright © 2015 Ram Subramaniam. All rights reserved.
//

import Foundation

class KreveldViewshedImpl {

    func calculateViewshed (demData: DEMData, observPt: ElevationPoint, radius: Int) ->[[Int]] {
        var viewshedMatrix = [[Int]](count:Srtm3.MAX_SIZE, repeatedValue:[Int](count:Srtm3.MAX_SIZE, repeatedValue:0))
        
        let startTime: Int64 = getCurrentMillis()
        
        let KreveldEventTypeEnter:Int = 1
        let KreveldEventTypeCenter:Int = 2
        let KreveldEventTypeExit:Int = 3
        let KreveldEventTypeOther:Int = 0
        struct Point1 { // Dummy structure TODO: get rid off it
            let x: Int
            let y: Int
        }
        let dummy: Point1 = Point1(x: -1, y: -1)
        
        let observerPtHeight: ElevationPoint = demData.getHeightedPoint(observPt.getXCoor(), yTemp: observPt.getYCoor())
        observPt.height = observerPtHeight.height
        
        let demDataMatrix: [[Int]] = demData.getDem2DMatrix()
        let kreveldActive: KreveldActiveBTree = KreveldActiveBTree(reference: observPt)

        // create a queue with the dummy KreveldSweepEventNode event with the eventType OTHER...so the total event count in the queue is one more than normal
        var sweepEventQueue = PriorityQueue(ascending: true, startingValues: [KreveldSweepEventNode(state: dummy, eventType: KreveldEventTypeOther,
            dataElevPoint: observPt, observerViewPt: observPt, angle: calculateAngle(observPt, view: observPt, type: KreveldEventTypeOther), distance: 0.0)])
        
        //  fill the EventList with all points
        var dataCounter: Int = 0
        let cellsInRadius:[(x:Int, y:Int)] = getCellsInRadius(observPt.getXCoor(), inY: observPt.getYCoor(), radius: radius)
        
        for (x, y) in cellsInRadius {
            dataCounter++
            //print("x: \(x)\t\ty: \(y)\t\t\(demDataMatrix[x][y])")
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
        print("Data added to queue in: \(Double(elapsedTime)) (ms)")
        print("Total dataCounter: \(dataCounter)")
        let elevPoints: [ElevationPoint] = pointsOnLine(demData, viewpoint: observPt);
        
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
        print("DEM processed in: \(Double(elapsedTime)) (ms)")
        
        print("ENTER: \(counterEnter)")
        print("CENTER: \(counterCenter)")
        print("EXIT: \(counterExit)")
        print("VISIBLE POINTS: \(visiblePtCounter)")
        print("\n")
        
        // should return the updated DEM data...
        return viewshedMatrix
    }
    
    // finds out all the elevation points with in the selected radius
    private func getCellsInRadius(inX: Int, inY: Int, radius: Int) -> [(x:Int,y:Int)] {
        var cellsInRadius:[(x:Int, y:Int)] = []
        
        for (var a = inX - radius; a <= inX + radius; a++) {
            for (var b:Int = (inY - radius); b <= inY + radius; b++) {
                cellsInRadius.append((a, Int(b)))
            }
            //print("\t\(cellsInRadius)")
        }
        return cellsInRadius
    }
    
    // Viewpoint starting point , point of observation
    // return All points that lie to the right of the starting point and have the same y-coordinate
    func pointsOnLine(d: DEMData, viewpoint: ElevationPoint) -> [ElevationPoint] {
        let xCoor: Int = viewpoint.getXCoor()
        let maxXcoor: Int = d.getNcols() - 1
        
        var elevPointOnline: [ElevationPoint] = []
        let iterateCount: Int = xCoor + 1
        
        // TODO - verify & make sure its "less than or equal to"
        for var i = iterateCount; i <= maxXcoor; i++ {
            let tmp:ElevationPoint = d.getHeightedPoint(i, yTemp: viewpoint.getYCoor())
            elevPointOnline.append(tmp)
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
    func getQuadrant(x: Int, y: Int) -> Int {
        if (x > 0) {
            if (y > 0) {
                return 1
            } else {
                return 4
            }
        }
        if (x < 0) {
            if (y > 0) {
                return 2
            } else {
                return 3
            }
        }
        return 0 // This should never be reached
    }
    
    func getCurrentMillis()->Int64{
        return  Int64(NSDate().timeIntervalSince1970 * 1000)
    }
    
}

