public class Node : Hashable, Equatable {
    
    // MARK: Properties
    public var displayName: String
    public var uniqueId: String
    
    init(uniqueId:String, displayName:String) {
        self.displayName = displayName
        self.uniqueId = uniqueId
    }
    
    public var hashValue: Int { return uniqueId.hash }
}

public func ==(lhs: Node, rhs: Node) -> Bool {
    return lhs.uniqueId == rhs.uniqueId
}