import PeerKit
import MultipeerConnectivity

public class Node : Hashable, Equatable {
    
    // MARK: Properties
    public var displayName: String
    public var uniqueId: String
    
    init(uniqueId:String, displayName:String) {
        self.displayName = displayName
        self.uniqueId = uniqueId
    }
    
    convenience init(mcPeerId: MCPeerID) {
        self.init(uniqueId: mcPeerId.displayName.componentsSeparatedByString(PeerKit.ID_DELIMITER)[1],
                  displayName: mcPeerId.displayName.componentsSeparatedByString(PeerKit.ID_DELIMITER)[0])
    }
    
    convenience init(uniquePeerKitName: String) {
        self.init(uniqueId: uniquePeerKitName.componentsSeparatedByString(PeerKit.ID_DELIMITER)[1],
                  displayName: uniquePeerKitName.componentsSeparatedByString(PeerKit.ID_DELIMITER)[0])
    }
    
    public var hashValue: Int { return uniqueId.hash }
}

public func ==(lhs: Node, rhs: Node) -> Bool {
    return lhs.uniqueId == rhs.uniqueId
}