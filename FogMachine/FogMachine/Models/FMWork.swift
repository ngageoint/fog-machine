import Foundation

/**
 
 Classes extending this should contain information that needs to get sent to the nodes in processWork().  See FMTool.
 
 */
open class FMWork: FMCoding {
    
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
