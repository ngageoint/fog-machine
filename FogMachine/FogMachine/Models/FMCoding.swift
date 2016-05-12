import Foundation

public class FMCoding: NSObject, NSCoding {
    
    // Keep a uuid for possible identification purposes, may not be needed
    public private(set) var uuid: String = NSUUID().UUIDString
    
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