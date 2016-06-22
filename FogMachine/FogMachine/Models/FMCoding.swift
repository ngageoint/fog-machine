import Foundation

/**
 
 Used to encode and decode information for classes extending FMWork and FMResult
 
 */
public class FMCoding: NSObject, NSCoding {
    
    /// A uuid to identify this information
    public private(set) var uuid: String = NSUUID().UUIDString
    
    // MARK: NSObject
    
    public override init() {
        super.init()
    }
    
    // MARK: NSCoding
    
    required public init(coder decoder: NSCoder) {
        self.uuid = decoder.decodeObjectForKey("uuid") as! String
    }
    
    public func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(self.uuid, forKey: "uuid")
    }
}