import Foundation


/**
 
 Finds a viewshed using Van Kreveld's method.  More acurate, but slower.
 
 */
public class VanKreveldViewshed : ViewsehdAlgorithm {
    
    let elevationDataGrid: DataGrid
    let perimeter: Perimeter;
    let observer: Observer
    
    init(elevationDataGrid: DataGrid, perimeter: Perimeter, observer: Observer) {
        self.elevationDataGrid = elevationDataGrid
        self.observer = observer
        self.perimeter = perimeter
    }
    
    public func runViewshed() -> DataGrid {
        
//        let KreveldEventTypeEnter:Int = 1
//        let KreveldEventTypeCenter:Int = 2
//        let KreveldEventTypeExit:Int = 3
//        let KreveldEventTypeOther:Int = 0 // only be used on creation/initialization
//        
//        let observerPtHeight = elevationMatrix[observPt.getXCoord()][observPt.getYCoord()]
//        observPt.height = observerPtHeight + observPt.getHeight()
//    
//        
//        var sweepEventQueue = PriorityQueue(ascending: true, startingValues: [KreveldSweepEventNode(eventType: KreveldEventTypeOther, dataElevPoint: observPt, observerViewPt: observPt, angle: calculateAngle(observPt, view: observPt, type: KreveldEventTypeOther), distance: 0.0)])
//        
//        //  fill the EventList with all points
//        for (x, y) in cellsInRadius {
//            let elevationAtXandYInt = elevationMatrix[x][y]
//            
//            
//            let elevPointData: ElevationPoint = ElevationPoint (xCoord: x, yCoord: y , h: elevationAtXandYInt)
//            if (isThisObserverPoint) {
//                if (elevPointData.getXCoord() == observPt.getXCoord() && elevPointData.getYCoord() == observPt.getYCoord()) {
//                    isThisObserverPoint = false
//                    continue
//                }
//            }
//            let sweepEnterEventList: KreveldSweepEventNode = KreveldSweepEventNode(eventType: 1, dataElevPoint: elevPointData, observerViewPt: observPt, angle: calculateAngle(elevPointData, view: observPt, type: 1), distance: calcDistance(elevPointData, observerViewPt: observPt))
//            let sweepCenterEventList: KreveldSweepEventNode = KreveldSweepEventNode(eventType: 2, dataElevPoint: elevPointData, observerViewPt: observPt, angle: calculateAngle(elevPointData, view: observPt, type: 2), distance: calcDistance(elevPointData, observerViewPt: observPt))
//            let sweepExitEventList: KreveldSweepEventNode = KreveldSweepEventNode(eventType: 3, dataElevPoint: elevPointData, observerViewPt: observPt, angle: calculateAngle(elevPointData, view: observPt, type: 3), distance: calcDistance(elevPointData, observerViewPt: observPt))
//            
//            sweepEventQueue.push(sweepEnterEventList)
//            sweepEventQueue.push(sweepExitEventList)
//            sweepEventQueue.push(sweepCenterEventList)
//        }
//        
//        var kreveldActive: KreveldActiveBTree = KreveldActiveBTree(reference: observer)
//        
//        let elevPoints: [ElevationPoint] = pointsOnLine(elevationMatrix, viewpoint: observPt, radius: radius, numQuadrants: numQuadrants);
//        for elevPoint in elevPoints {
//            kreveldActive.insert(elevPoint);
//        }
//        
//        while !sweepEventQueue.isEmpty {
//            let sweepEvent: KreveldSweepEventNode! = sweepEventQueue.pop()
//            
//            switch sweepEvent.getEventType() {
//            case KreveldEventTypeEnter:
//                kreveldActive.insert(sweepEvent.getDataElevPoint())
//            case KreveldEventTypeCenter:
//                
//                if (kreveldActive.isVisible(sweepEvent.getDataElevPoint())) {
//                    let x: Int = sweepEvent.getDataElevPoint().getXCoord()
//                    let y: Int = sweepEvent.getDataElevPoint().getYCoord()
//                    //visiblePtCounter++
//                    viewshedMatrix[x][y] = 1
//                } else {
//                    
//                }
//            case KreveldEventTypeExit:
//                kreveldActive.delete(sweepEvent.getDataElevPoint())
//            default:
//                let _: Int
//            }
//            
//        }
//        return viewshedMatrix
        return DataGrid(data: elevationDataGrid.data, boundingBoxAreaExtent: elevationDataGrid.boundingBoxAreaExtent, resolution: elevationDataGrid.resolution)
    }
    
    // calculates the angle from the start point to all four corners of a pixel
    // atan2 function automatically calculates the correct angle for each quadrant
    // return Angle between the starting point and cornerstone of a pixel
//    func calculateAngle(point1: ElevationPoint, view: ElevationPoint, type: Int) -> Double {
//        let yc: Double = Double (point1.getYCoord())
//        let yv: Double =   Double (view.getYCoord())
//        
//        let xc: Double = Double (point1.getXCoord())
//        let xv: Double =   Double (view.getXCoord())
//        
//        let dy: Double =  yc - yv
//        let dx:Double = xc - xv
//        
//        // TODO - verify the calc
//        // Pixel has same y - coordinate as the starting point is , the right of it and has event type ENTER
//        // hen the corresponding corner of the pixel is retrieved and calculates the angles thereto
//        if (dy == 0 && dx > 0 && type == KreveldEventTypeEnter) {
//            var angle: Double = atan2(-0.5, dx - 0.5)
//            angle += 2 * M_PI
//            return angle
//            // Pixel has same y - coordinate as the starting point is , the right of it and has event type EXIT
//        } else if (dy == 0 && dx > 0 && type == KreveldEventTypeExit) {
//            let angle: Double = atan2(+0.5, dx - 0.5)
//            return angle
//        } else if (type == KreveldEventTypeCenter) {
//            var angle: Double = atan2(dy, dx)
//            if (angle < 0) {
//                angle += 2 * M_PI
//            }
//            return angle
//            // EventType ENTER: four corners as possible candidates
//            // compute all four angles to the corners and take the smallest
//        } else if (type == KreveldEventTypeEnter) {
//            var a1: Double = atan2(dy + 0.5, dx + 0.5)
//            if (a1 < 0) {
//                a1 += 2 * M_PI
//            }
//            var a2: Double = atan2(dy - 0.5, dx + 0.5);
//            if (a2 < 0) {
//                a2 += 2 * M_PI
//            }
//            var a3: Double = atan2(dy + 0.5, dx - 0.5);
//            if (a3 < 0) {
//                a3 += 2 * M_PI
//            }
//            var a4:Double = atan2(dy - 0.5, dx - 0.5);
//            if (a4 < 0) {
//                a4 += 2 * M_PI
//            }
//            
//            let angle: Double = min(min(a1, a2), min(a3, a4))
//            return angle
//        } else {
//            var a1: Double = atan2(dy + 0.5, dx + 0.5)
//            if (a1 < 0) {
//                a1 += 2 * M_PI
//            }
//            var a2: Double = atan2(dy - 0.5, dx + 0.5)
//            if (a2 < 0) {
//                a2 += 2 * M_PI
//            }
//            var a3: Double = atan2(dy + 0.5, dx - 0.5)
//            if (a3 < 0) {
//                a3 += 2 * M_PI
//            }
//            var a4:Double = atan2(dy - 0.5, dx - 0.5)
//            if (a4 < 0) {
//                a4 += 2 * M_PI
//            }
//            
//            let angle: Double = max(max(a1, a2), max(a3, a4))
//            return angle
//        }
//    }
}

