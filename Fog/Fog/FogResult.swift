import Foundation

public class FogResult: FogCoding {
    var processWorkTime:CFAbsoluteTime = 0.0
    
    public init(processWorkTime:CFAbsoluteTime) {
        super.init()
        self.processWorkTime = processWorkTime;
    }
    
    required public init(coder decoder: NSCoder) {
        super.init(coder: decoder)
        self.processWorkTime = decoder.decodeDoubleForKey("processWorkTime")
    }
    
    public override func encodeWithCoder(coder: NSCoder) {
        super.encodeWithCoder(coder);
        coder.encodeDouble(self.processWorkTime, forKey: "processWorkTime")
    }
}
