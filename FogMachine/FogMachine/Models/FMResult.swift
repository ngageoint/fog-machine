import Foundation

/**
 
 Classes extending this should contain information that needs to get sent back to the initiator node for mereResults().  See FMTool.
 
 */
public class FMResult: FMCoding {
    
    // MARK: NSObject
    
    public override init() {
        super.init()
    }
    
    // MARK: FMCoding
    
    required public init(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    public override func encodeWithCoder(coder: NSCoder) {
        super.encodeWithCoder(coder);
    }
}
