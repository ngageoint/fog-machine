import Foundation

/**
 
 Used to encode and decode information for classes extending FMWork and FMResult
 
 */
open class FMCoding: NSObject, Codable {
    /// A uuid to identify this information
    public private(set) var uuid: String = UUID().uuidString
    enum FMCodingKeys: String, CodingKey {
        case uuid
    }
    
    // MARK: NSObject
    
    public override init() {
        super.init()
    }
    
    // MARK: NSCoding
    
    required open init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.uuid = try container.decode(String.self, forKey: .uuid)
    }
        
    open func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: FMCodingKeys.self)
        try container.encode(self.uuid, forKey: .uuid)
    }
}
