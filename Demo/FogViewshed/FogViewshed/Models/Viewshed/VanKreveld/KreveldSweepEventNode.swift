import Foundation

let KreveldEventTypeEnter:Int = 1
let KreveldEventTypeCenter:Int = 2
let KreveldEventTypeExit:Int = 3
let KreveldEventTypeOther:Int = 0

class KreveldSweepEventNode: Comparable {
    let eventType: Int
    let dataElevPoint, observerViewPt: ElevationPoint
    let angle: Double
    let distance: Double
    
    init(eventType: Int, dataElevPoint: ElevationPoint, observerViewPt: ElevationPoint, angle: Double, distance: Double) {
        self.eventType = eventType
        self.dataElevPoint = dataElevPoint
        self.observerViewPt = observerViewPt
        self.angle = angle
        self.distance = distance
    }
    
    func getEventType() -> Int  {
        return self.eventType;
    }
    
    func getDataElevPoint() -> ElevationPoint {
        return self.dataElevPoint;
    }
    
    func getAngle() -> Double {
        return self.angle;
    }
    func getDistance() -> Double {
        return self.distance;
    }
    func getPoint() -> ElevationPoint{
        return self.dataElevPoint
    }
    var hashValue: Int {
        return (Int) (angle)
    }
}

// compares angle between two sweep events and inserts them accordingly
// first sorted in the priority queue according to an angle , if these
// equal according to distance from the starting point and if it is right after Type (EXIT or ENTER)
func <  (lhs: KreveldSweepEventNode, rhs: KreveldSweepEventNode) -> Bool {
    //return (lhs.angle) < (rhs.angle)
    if lhs.angle < rhs.angle {
        return true
    }
    if lhs.angle > rhs.angle {
        return false
    }
    // TODO Commenting the following lines to see if this improves the performace..
    if lhs.distance < rhs.distance {
        return true
    }
    if lhs.distance > rhs.distance {
        return false
    }
    if lhs.eventType == KreveldEventTypeEnter {
        return false
    }
    return false
}

func == (lhs: KreveldSweepEventNode, rhs: KreveldSweepEventNode) -> Bool {
    // TODO Commenting to see if this improves the performace..
    // stopped comparing the entire object to conserve time!
    // if the angles are equal compare the entire object
    if lhs.angle == rhs.angle {
        if (lhs === rhs) {
            return true
        } else {
            return false
        }
    }
    return false
}

