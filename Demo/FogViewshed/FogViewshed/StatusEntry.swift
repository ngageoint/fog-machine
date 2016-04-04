import Foundation

public class StatusEntry {
    
    var key: Double = 0.0
    var value : ElevationPoint
    var maxSlope :Double = 0.0
    var slope : Double = 0.0
    var left : StatusEntry! = nil
    var right: StatusEntry! = nil
    var parent: StatusEntry! = nil
    var flag: Bool
    
    init (key: Double, value: ElevationPoint, slope: Double, parent: StatusEntry!) {
        self.key = key;
        self.value = value;
        self.maxSlope = slope;
        self.slope = slope;
        self.parent = parent;
        self.flag = false
    }
    
    public func getKey () -> Double {
        return self.key
    }
    
    public func getValue() -> ElevationPoint {
        return self.value;
    }
    
    public func getMaxSlope() -> Double {
        return self.maxSlope
    }
}