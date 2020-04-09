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
    
    required open init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    open override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
    }
}
