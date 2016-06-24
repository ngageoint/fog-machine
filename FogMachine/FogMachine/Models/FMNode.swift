import Foundation
import MultipeerConnectivity

/**
 
 Node represents a device in the network.  You can retrive the nodes in your network using methods from the `FogMachine` instance
 
 */
public class FMNode : CustomStringConvertible, Hashable, Equatable {
    
    // MARK: Properties

    /// The node id. Ex: 0BD4B032-9A5E-4F1A-90F9-EAAC50175CAC
    public private(set) var uniqueId: String
    /// Name of the node.  Usually the device name.  Ex: Alan Turing's iPhone
    public private(set) var name: String
    /// The id used for multipeer connectivity.
    public private(set) var mcPeerID: MCPeerID
    
    /**
     
     Create a new node.  Used by FogMachine.
     
     - parameter uniqueId:
     - parameter name:     The name of the node.  Usually the device name.  Ex: Alan Turing's iPhone
     - parameter mcPeerID: The id used for multipeer connectivity.
     
     - returns: A new FMNode
     
     */
    public init(uniqueId:String, name:String, mcPeerID:MCPeerID) {
        self.name = name
        self.uniqueId = uniqueId
        self.mcPeerID = mcPeerID;
        self.hashValue = uniqueId.hash
    }
    
    // MARK: CustomStringConvertible
    
    /// name and id of this node
    public var description: String {
        return name + " " + uniqueId
    }
    
    // MARK: Hashable
    public var hashValue: Int
}

/**
 
 Determines if two FMNodes are equivalent
 
 - parameter lhs: left-hand FMNode
 - parameter rhs: right-hand FMNode
 
 - returns: true iff the lhs.uniqueId == rhs.uniqueId, false otherwise
 
 */
public func ==(lhs: FMNode, rhs: FMNode) -> Bool {
    return lhs.uniqueId == rhs.uniqueId
}