import Foundation

public class FogWork: FogSerializable {
    
    public init() {
        
    }
    
    public required init (serializedData: [String:NSObject]) {
        
    }
    
    public func getDataToSerialize() -> [String:NSObject] {
        return ["test": "testvalue"];
    }
}
