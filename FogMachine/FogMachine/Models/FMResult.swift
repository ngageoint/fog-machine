import Foundation

/**
 
 Classes extending this should contain information that needs to get sent back to the initiator node for mereResults().  See FMTool.
 
 */
open class FMResult: FMCoding {
    
    // MARK: NSObject
    
    public override init() {
        super.init()
    }
    
    // MARK: FMCoding
    
    required public init(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
    }
}
