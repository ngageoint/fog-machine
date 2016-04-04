import Foundation


public struct ElevationPoint {
    var height: Int = 0
    var xCoord: Int = 0
    var yCoord: Int = 0
    
    init(xCoord :Int, yCoord: Int) {
        self.xCoord = xCoord
        self.yCoord = yCoord
    }
    
    init(xCoord: Int, yCoord: Int, h: Int) {
        self.xCoord = xCoord
        self.yCoord = yCoord
        self.height = h
    }
    
    public func getHeight() -> Int {
        return self.height;
    }
    
    public func equalsPosition (p: ElevationPoint) -> Bool {
        if (p.getXCoord() == self.getXCoord() &&  p.getYCoord() == self.getYCoord()) {
            return true
        } else {
            return false
        }
    }
    
    public func calcSlope (to: ElevationPoint) -> Double {
        let localHeight: Int = to.getHeight() - self.getHeight()
        let result: Double = Double(localHeight)/calcDistance(to)
        return result
    }
    
    public func getXCoord() -> Int {
        return self.xCoord
    }
    
    public func getYCoord() -> Int {
        return self.yCoord
    }
    
    //Calculates the euclidean distance (distance between two points in Euclidean space) to another point in 2D space.
    //to Other point
    // return Distance between this point and <tt>to</tt>
    public func calcDistance(to:ElevationPoint) -> Double {
        // distance between this (observer) point and the "to point"
        let distX: Double = Double (self.getXCoord() - to.getXCoord())
        let distY: Double = Double (self.getYCoord() - to.getYCoord())
        return sqrt((distX*distX) + (distY*distY))
    }
}
