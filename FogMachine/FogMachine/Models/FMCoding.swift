import Foundation

/**
 
 Used to encode and decode information for classes extending FMWork and FMResult
 
 */
open class FMCoding: NSObject, NSCoding {
    
    // A uuid to identify this information
    open fileprivate(set) var uuid: String = UUID().uuidString
    
    // MARK: NSObject
    
    public override init() {
        super.init()
    }
    
    // MARK: NSCoding
    
    required public init(coder decoder: NSCoder) {
        self.uuid = decoder.decodeObject(forKey: "uuid") as! String
    }
    
    open func encode(with coder: NSCoder) {
        coder.encode(self.uuid, forKey: "uuid")
    }
}
