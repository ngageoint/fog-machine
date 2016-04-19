import PeerKit
import MultipeerConnectivity

public class Node : CustomStringConvertible, Hashable, Equatable {

    public static let NAME = "Name"
    public static let UNIQUEID = "UniqueId"
    public static let MCPEERID = "MCPeerID"
    public static let HASH = "Hash"
    
    // MARK: Properties
    public var name: String
    public var uniqueId: String
    public private(set) var mcPeerID: MCPeerID
    
    public var description: String{
        return name + " " + uniqueId
    }
    public var hashValue: Int
    
    public init(uniqueId:String, name:String, mcPeerID:MCPeerID) {
        self.name = name
        self.uniqueId = uniqueId
        self.mcPeerID = mcPeerID;
        self.hashValue = uniqueId.hash
    }
    
//    public required init (serializedData: [String:NSObject]) {
//        self.name = serializedData[Node.NAME] as! String
//        self.uniqueId = serializedData[Node.UNIQUEID] as! String
//        self.mcPeerID = serializedData[Node.MCPEERID] as! MCPeerID
//        self.hashValue = serializedData[Node.HASH] as! Int
//    }
//    
//    public func getDataToSerialize() -> [String:NSObject] {
//        return [
//            Node.NAME: name,
//            Node.UNIQUEID: uniqueId,
//            Node.MCPEERID: mcPeerID,
//            Node.HASH: hashValue];
//    }
    
    // TODO: status/lastSeen/DeviceInfo
}

public func ==(lhs: Node, rhs: Node) -> Bool {
    return lhs.uniqueId == rhs.uniqueId
}