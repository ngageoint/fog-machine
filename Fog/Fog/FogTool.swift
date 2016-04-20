import Foundation
import MultipeerConnectivity

/**
 Base class for applications that use FogMachine to overwrite.  Has a lifecycle that you should abide by.  You should extend this class and provide implmentations for the following routines:
 createWork
 processWork
 mergeResults
 
 */
public class FogTool {
    
    public init() {
        
    }
    
    public func name() -> String {
        return "BASE FOGTOOL"
    }
    
    /**
     
     This gets called n times by FogMachine on the initiator node, where n is the number of nodes in the network (including yourself)
     This function creates the information that will be sent to each node in the network.  As a user of Fog Machine, you must provide an implmentation for this routine!
     
     @param node The node in the network that will process this piece of work
     @param nodeNumber Of the nodes in the network an ordered nuber that indicates which node this is.  Ex: 2
     @param numberOfNodes The number of Nodes in the network for this lifecycle  Ex: 3
     
     @return Work The information that needs to get send to the node
     
     */
    public func createWork(node:Node, nodeNumber:UInt, numberOfNodes:UInt) -> FogWork {
        return FogWork();
    }
    
    /**
     
     This funciton will get called with one piece of work that was created in createWork.  Each node will process it's own work, and therefore this funtion will get called once on each device, each call with a different piece of work. (excluding the retry logic)
     
     @param node The node that is processing this piece of work
     @param work The work to be processed by this node
     
     @return FogResult The information that needs to be returned to the initiator
     
     */
    public func processWork(node:Node, fromNode:Node, work: FogWork) -> FogResult {
        return FogResult();
    }
    
    /**
     
     This gets called only once by FogMachine on the initiator node.  It is resposible for merging all the results.
     
     @param node The node processing the work.  This is you!
     @param nodeToResult All of the results tied to each node.
     
     */
    public func mergeResults(node:Node, nodeToResult :[Node:FogResult]) -> Void {
        
    }
    
    
    /**
     
     This is called when a peer connects to the network
     
     */
    public func onPeerConnect(myNode:Node, connectedNode:Node) {
        
    }
    
    /**
     
     This is called when a peer disconnects from the network
     
     */
    public func onPeerDisconnect(myNode:Node, disconnectedNode:Node) {
        
    }
}