import Foundation

/**
 
 This class provides the a simple lifecycle that your applicaiton can utilize.  Extend this class and provide implementations for createWork, processWork and mergeResults, in order to make your custom tool.  See the example projects and the README for more information.
 
 */
public class FMTool {
    
    public init() {
        
    }

    /**
     
      A unique identified for this tool.  It should be consistent accross nodes, but it can be changed in order to version you tool.
     
     - returns: unique identified for this tool
     
     */
    public func id() -> UInt32 {
        return 4229232399
    }
    
    /**
     
     Description of your tool for logging
     
     - returns: tool description.  Ex: My Hello world tool
     
     */
    public func name() -> String {
        return "BASE FOGTOOL"
    }
    
    /**
     
     This gets called n times by FogMachine on the initiator node, where n is the number of nodes in the network (including yourself). This function creates the information that will be sent to each node in the network.  As a user of Fog Machine, you must provide an implmentation for this routine.
     
     - parameter node:          The FMNode in the network that will process this piece of work.
     - parameter nodeNumber:    An ordered nuber that indicates which node this is.  Ex: 2.
     - parameter numberOfNodes: The number of Nodes in the network for this lifecycle  Ex: 3.
     
     - returns: FMWork that contians the information that needs to get send to the node to run process work.
     
     */
    public func createWork(node:FMNode, nodeNumber:UInt, numberOfNodes:UInt) -> FMWork {
        return FMWork();
    }
    
    /**
     
     This function will get called with one piece of work that was created in createWork.  Each node will process its own work, and therefore this funtion will get called once on each device, each call with a different piece of work (excluding retry logic).
     
     - parameter node:     The node that is processing this piece of work.
     - parameter fromNode: The initiator node.
     - parameter work:     The work to be processed by this node.
     
     - returns: FMResult The information that needs to be returned to the initiator.
     
     */
    public func processWork(node:FMNode, fromNode:FMNode, work: FMWork) -> FMResult {
        return FMResult();
    }
    
    /**
     
     This gets called only once by FogMachine on the initiator node.  It is responsible for merging all the results from the nodes in the network.
     
     - parameter node:         The initiator node.  This is you.
     - parameter nodeToResult: All of the results matched to the node that create each result.
     
     */
    public func mergeResults(node:FMNode, nodeToResult :[FMNode:FMResult]) -> Void {
        
    }
    
    
    /**
     
     This is called when a peer connects to the network.
     
     - parameter myNode:        This is you.
     - parameter connectedNode: The FMNode that connected
     
     */
    public func onPeerConnect(myNode:FMNode, connectedNode:FMNode) {
        
    }
    
    /**
     
     This is called when a peer disconnects from the network.
     
     - parameter myNode:           This is you.
     - parameter disconnectedNode: The FMNode that disconnected
     
     */
    public func onPeerDisconnect(myNode:FMNode, disconnectedNode:FMNode) {
        
    }
    
    /**
     
     Called when FogMachine logs/sends messages
     
     - parameter format: Stirng you want to log.
     
     */
    public func onLog(format:String) {
        
    }
}