import Foundation

public class VanKreveldStatusEntry {
    
    var key: Double = 0.0
    var value : VanKreveldCell
    var maxSlope :Double = 0.0
    var slope : Double = 0.0
    var left : VanKreveldStatusEntry! = nil
    var right: VanKreveldStatusEntry! = nil
    var parent: VanKreveldStatusEntry! = nil
    var flag: Bool
    
    init (key: Double, value: VanKreveldCell, slope: Double, parent: VanKreveldStatusEntry!) {
        self.key = key;
        self.value = value;
        self.maxSlope = slope;
        self.slope = slope;
        self.parent = parent;
        self.flag = false
    }
}