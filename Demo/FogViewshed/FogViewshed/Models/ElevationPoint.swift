import Foundation

public class ElevationPoint {
    var height: Int
    var xCoord: Int
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

    public func getXCoord() -> Int {
        return self.xCoord
    }

    public func getYCoord() -> Int {
        return self.yCoord
    }
}
