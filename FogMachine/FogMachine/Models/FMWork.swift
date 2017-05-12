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
    
    required public init(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
    }
}
