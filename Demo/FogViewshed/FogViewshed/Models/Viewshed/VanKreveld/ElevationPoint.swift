import Foundation

public class ElevationPoint {
    var height: Int
    var xCoord: Int
    var yCoord: Int

    init(xCoord: Int, yCoord: Int, height: Int) {
        self.xCoord = xCoord
        self.yCoord = yCoord
        self.height = height
    }

    public func equalsPosition (p: ElevationPoint) -> Bool {
        if (p.xCoord == self.xCoord &&  p.yCoord == self.yCoord) {
            return true
        } else {
            return false
        }
    }
}
