import PeerKit
import MultipeerConnectivity

public class Node : Hashable, Equatable, MPCSerializable {
    
    
    // MARK: Properties
    
    
    public var displayName: String
    public var uniqueId: String
    public var hashValue: Int
    public var mpcSerialized : NSData {
        let result = NSKeyedArchiver.archivedDataWithRootObject([
            Fog.Node.DISPLAY_NAME: displayName,
            Fog.Node.UNIQUE_ID: uniqueId,
            Fog.Node.HASH: hashValue])
        
        return result
    }
    
    
    public init(uniqueId:String, displayName:String) {
        self.displayName = displayName
        self.uniqueId = uniqueId
        self.hashValue = uniqueId.hash
    }
    
    
    public convenience init(mcPeerId: MCPeerID) {
        self.init(uniqueId: mcPeerId.displayName.componentsSeparatedByString(PeerKit.ID_DELIMITER)[1],
                  displayName: mcPeerId.displayName.componentsSeparatedByString(PeerKit.ID_DELIMITER)[0])
    }
    
    
    public convenience init(namePlusUniqueId: String) {
        self.init(uniqueId: namePlusUniqueId.componentsSeparatedByString(PeerKit.ID_DELIMITER)[1],
                  displayName: namePlusUniqueId.componentsSeparatedByString(PeerKit.ID_DELIMITER)[0])
    }
    
    
    public required init (mpcSerialized: NSData) {
        let nodeData = NSKeyedUnarchiver.unarchiveObjectWithData(mpcSerialized) as! [String: NSObject]
        self.displayName = nodeData[Fog.Node.DISPLAY_NAME] as! String
        self.uniqueId = nodeData[Fog.Node.UNIQUE_ID] as! String
        self.hashValue = nodeData[Fog.Node.HASH] as! Int
    }
    
    
    public func getMcPeerIdDisplayName() -> String {
        return displayName + PeerKit.ID_DELIMITER + uniqueId
    }
    
    
    public func isSelf() -> Bool {
        return getMcPeerIdDisplayName() == PeerKit.myName
    }
    
    
    // TODO: status/lastSeen/DeviceInfo/equals
    
    
}

public func ==(lhs: Node, rhs: Node) -> Bool {
    return lhs.uniqueId == rhs.uniqueId
}