import Foundation
import PeerKit
import MultipeerConnectivity

/**
 
 This is a singleton! Use it that way
 
 This is the class your app should interface with.  It will handle all the connection stuff and the distribution of processing in your network.
 
 You should extend FogTool and pass an instance into this class.
 
 Call fogMachineInstance.execute() to run your tool in your network!
 
 */
public class FogMachine {
    
    public static let fogMachineInstance = FogMachine()
    
    // Your application will set this
    private var fogTool: FogTool = FogTool()
    
    // used to control concurrency.  It synchronizes many of the data structures in the class
    private let lock = dispatch_queue_create("mil.nga.giat.fogmachine", nil)
    
    // event names to be used with PeerKit
    private let sendWorkEvent: String = "sendWorkEvent"
    private let sendResultEvent: String = "sendResultEvent"
    
    // used to time stuff
    // TODO : replace with a better metric colletion
    private let executionTimer = Timer()
    
    private init() {
    }
    
    // get your tool
    public func getTool() -> FogTool {
        return fogTool
    }
    
    // set the tool you want to use with FogMachine
    public func setTool(fogTool: FogTool) {
        self.fogTool = fogTool
        
        // When a peer connects, log the connection and delegate to the tool
        PeerKit.onConnect = { (myPeerID: MCPeerID, peerID: MCPeerID) -> Void in
            let selfNode:Node = self.getSelfNode()
            let peerNode:Node = Node(uniqueId: peerID.displayName.componentsSeparatedByString(PeerKit.ID_DELIMITER)[1], name: peerID.displayName.componentsSeparatedByString(PeerKit.ID_DELIMITER)[0], mcPeerID: peerID)
            
            // make sure this is you!
            //guard myPeerID == selfNode.mcPeerID else { throw FogMachineError.PeerIDError }
            if(myPeerID != selfNode.mcPeerID) {
                NSLog("ERROR: Node id: " + selfNode.mcPeerID.displayName + " does not match peerID: " + myPeerID.displayName + ".")
            }
            
            NSLog(selfNode.description + " connected to " + peerNode.description)
            fogTool.onPeerConnect(selfNode, connectedNode: peerNode);
        }
        
        // When a peer disconnects, log the disconnection and delegate to the tool
        PeerKit.onDisconnect = { (myPeerID: MCPeerID, peerID: MCPeerID) -> Void in
            let selfNode:Node = self.getSelfNode()
            let peerNode:Node = Node(uniqueId: peerID.displayName.componentsSeparatedByString(PeerKit.ID_DELIMITER)[1], name: peerID.displayName.componentsSeparatedByString(PeerKit.ID_DELIMITER)[0], mcPeerID: peerID)
            
            // make sure this is you!
            //guard myPeerID == selfNode.mcPeerID else { throw FogMachineError.PeerIDError }
            if(myPeerID != selfNode.mcPeerID) {
                NSLog("ERROR: Node id: " + selfNode.mcPeerID.displayName + " does not match peerID: " + myPeerID.displayName + ".")
            }
            
            NSLog(peerNode.description + " disconnected from " + selfNode.description)
            fogTool.onPeerDisconnect(selfNode, disconnectedNode: peerNode);
        }
        
        // when a work request comes over the air, have the tool process the work
        PeerKit.eventBlocks[self.sendWorkEvent] = { (fromPeerID: MCPeerID, object: AnyObject?) -> Void in
            let selfNode: Node = self.getSelfNode()
            let fromNode: Node = Node(uniqueId: fromPeerID.displayName.componentsSeparatedByString(PeerKit.ID_DELIMITER)[1], name: fromPeerID.displayName.componentsSeparatedByString(PeerKit.ID_DELIMITER)[0], mcPeerID: fromPeerID)
            
            // deserialize the work
            let dataReceived = NSKeyedUnarchiver.unarchiveObjectWithData(object as! NSData) as! [String: NSObject]
            let sessionUUID:String = dataReceived["SessionID"] as! String
            let peerWork:FogWork =  NSKeyedUnarchiver.unarchiveObjectWithData(dataReceived["FogToolWork"] as! NSData) as! FogWork
            
            let workMirror = Mirror(reflecting: peerWork)
            
            NSLog(selfNode.description + " received \(workMirror.subjectType) to process from " + fromNode.description + " for session " + sessionUUID + ".  Starting to process work.")
            
            // process the work, and get a result
            let peerResult:FogResult = self.fogTool.processWork(selfNode, fromNode: fromNode, work: peerWork)

            let dataToSend:[String:NSObject] =
                ["FogToolResult": NSKeyedArchiver.archivedDataWithRootObject(peerResult),
                 "SessionID": sessionUUID];

            let peerResultMirror = Mirror(reflecting: peerResult)
            
            NSLog(selfNode.description + " done processing work.  Sending \(peerResultMirror.subjectType) back.")
            
            // send the result back
            PeerKit.sendEvent(self.sendResultEvent, object: NSKeyedArchiver.archivedDataWithRootObject(dataToSend), toPeers: [fromPeerID])
        }
    }
    
    // MARK: Properties
    
    public func getSelfNode() -> Node {
        return Node(uniqueId: PeerKit.myName.componentsSeparatedByString(PeerKit.ID_DELIMITER)[1], name: PeerKit.myName.componentsSeparatedByString(PeerKit.ID_DELIMITER)[0], mcPeerID: PeerKit.masterSession.myPeerId)
    }
    
    public func getPeerNodes() -> [Node] {
        var nodes: [Node] = []
        
        let mcPeerIDs: [MCPeerID] = PeerKit.masterSession.allConnectedPeers() ?? []
        for peerID in mcPeerIDs {
            nodes.append(Node(uniqueId: peerID.displayName.componentsSeparatedByString(PeerKit.ID_DELIMITER)[1], name: peerID.displayName.componentsSeparatedByString(PeerKit.ID_DELIMITER)[0], mcPeerID: peerID))
        }
        nodes.sortInPlace { (obj1, obj2) -> Bool in
            return obj1.uniqueId < obj2.uniqueId
        }
        return nodes
    }
    
    public func getAllNodes() -> [Node] {
        var nodes: [Node] = []
        nodes.append(getSelfNode())
        nodes += getPeerNodes()
        nodes.sortInPlace { (obj1, obj2) -> Bool in
            return obj1.uniqueId < obj2.uniqueId
        }
        return nodes
    }
    
    public func startSearchForPeers() {
        NSLog("searching for peers")
        // Service type can contain only ASCII lowercase letters, numbers, and hyphens.
        // It must be a unique string, at most 15 characters long
        // Note: Devices will only connect to other devices with the same serviceType value.
        let SERVICE_TYPE = "fog-machine"
        transceiver.startTransceiving(serviceType: SERVICE_TYPE)
    }
    
    // TODO : Should refactor this into a FogMachineData api ...
    // all the data structures below are session dependant!
    
    // keep a map of the session to the MCPeerIDs to the nodes for this session
    private var mcPeerIDToNode:[String:[MCPeerID:Node]] = [String:[MCPeerID:Node]]()
    
    // keep a map of the session to the Nodes to the works for this session, as nodes may come and go otherwise
    private var nodeToWork:[String:[Node:FogWork]] = [String:[Node:FogWork]]()
    
    // keep a map of the session to the Nodes to the results for this session, as nodes may come and go otherwise
    private var nodeToResult:[String:[Node:FogResult]] = [String:[Node:FogResult]]()
    
    // keep a map of the session to the Nodes to the roundTrip time.  The roundtrip time is the time it takes for a node to go out and come back
    private var nodeToRoundTripTimer:[String:[Node:Timer]] = [String:[Node:Timer]]()
    
    // has the execute method setup the reprocess work timers for this session?
    private var haveSetUpReprocessWork:[String:Bool] = [String:Bool]()
    
    /**
     
     This runs a FogTool!  Your app should call this!
     
     */
    public func execute() -> Void {
        // time how long the entire execution takes
        executionTimer.start()
        
        // this is a uuid to keep track on this session (a round of execution).  It's mostly used to make sure requests and responses happen correctly for a single session.
        let sessionUUID:String = NSUUID().UUIDString
        
        // create new data structures for this session
        mcPeerIDToNode[sessionUUID] = [MCPeerID:Node]()
        nodeToWork[sessionUUID] = [Node:FogWork]()
        nodeToResult[sessionUUID] = [Node:FogResult]()
        nodeToRoundTripTimer[sessionUUID] = [Node:Timer]()
        haveSetUpReprocessWork[sessionUUID] = false;
        
        for node in getAllNodes() {
            mcPeerIDToNode[sessionUUID]![node.mcPeerID] = node;
        }
        
        let numberOfNodes:UInt = UInt(mcPeerIDToNode[sessionUUID]!.count)
        NSLog("Executing " + fogTool.name() + " in session " + sessionUUID + " on \(numberOfNodes) nodes (including myself).")
        
        // when a result comes back over the air
        PeerKit.eventBlocks[self.sendResultEvent] = { (fromPeerID: MCPeerID, object: AnyObject?) -> Void in
            let selfNode: Node = self.getSelfNode()
            
            // deserialize the result!
            let dataReceived = NSKeyedUnarchiver.unarchiveObjectWithData(object as! NSData) as! [String: NSObject]
            let receivedSessionUUID:String = dataReceived["SessionID"] as! String
            
            // make sure this is the same session!
            if(self.mcPeerIDToNode.keys.contains(receivedSessionUUID)) {
                // store the result and merge results if needed
                dispatch_sync(self.lock) {
                    let fromNode: Node = self.mcPeerIDToNode[receivedSessionUUID]![fromPeerID]!
                    let peerResult:FogResult = NSKeyedUnarchiver.unarchiveObjectWithData(dataReceived["FogToolResult"] as! NSData) as! FogResult
                    let peerResultMirror = Mirror(reflecting: peerResult)
                    
                    let roundTripTime:CFAbsoluteTime = (self.nodeToRoundTripTimer[receivedSessionUUID]![fromNode]?.stop())!
                    NSLog(selfNode.description + " received \(peerResultMirror.subjectType) in session " + receivedSessionUUID + " from " + fromNode.description + " after " + String(format: "%.3f", roundTripTime) + " seconds, storing result.")
                    self.nodeToResult[receivedSessionUUID]![fromNode] = peerResult
                    self.finishAndMerge(selfNode, callerNode: fromNode, sessionUUID: receivedSessionUUID)
                }
            } else {
                NSLog(selfNode.description + " received result for session " + receivedSessionUUID + ", but that session no longer exists.  Discarding work.")
            }
        }
        
        // my work
        var selfWork:FogWork?
        // make the work for each node
        var nodeCount:UInt = 0
        for (mcPeerId, node) in mcPeerIDToNode[sessionUUID]! {
            if(node == getSelfNode()) {
                NSLog("Creating self work.")
            } else {
                NSLog("Creating work for " + node.description)
            }
            let work:FogWork = self.fogTool.createWork(node, nodeNumber: nodeCount, numberOfNodes: numberOfNodes)
            if(node == getSelfNode()) {
                selfWork = work
            }
            nodeToWork[sessionUUID]![node] = work
            nodeToRoundTripTimer[sessionUUID]![node] = Timer()
            nodeCount += 1
        }
        
        // send out all the work
        for (node, work) in nodeToWork[sessionUUID]! {
            if(node != getSelfNode()) {
                NSLog("Sending a work to " + node.description)
                
                let data:[String:NSObject] =
                ["FogToolWork": NSKeyedArchiver.archivedDataWithRootObject(work),
                 "SessionID": sessionUUID];
                dispatch_sync(self.lock) {
                    self.nodeToRoundTripTimer[sessionUUID]![node]?.start()
                }
                PeerKit.sendEvent(self.sendWorkEvent, object: NSKeyedArchiver.archivedDataWithRootObject(data), toPeers: [node.mcPeerID])
            }
        }
        
        // process your own work
        NSLog("Processing self work.")
        dispatch_sync(self.lock) {
            self.nodeToRoundTripTimer[sessionUUID]![self.getSelfNode()]?.start()
        }
        let selfResult:FogResult = self.fogTool.processWork(getSelfNode(), fromNode: getSelfNode(), work: selfWork!)
        
        // store the result and merge results if needed
        dispatch_sync(self.lock) {
            self.nodeToRoundTripTimer[sessionUUID]![self.getSelfNode()]?.stop()
            NSLog("Storing self result.")
            self.nodeToResult[sessionUUID]![self.getSelfNode()] = selfResult
            self.finishAndMerge(self.getSelfNode(), callerNode: self.getSelfNode(), sessionUUID: sessionUUID)
        }
    }
    
    private func finishAndMerge(selfNode:Node, callerNode:Node, sessionUUID:String) {
        // did we get all the results, yet?
        if(nodeToWork[sessionUUID]!.count == nodeToResult[sessionUUID]!.count) {
            // remove sendResultEvent from peerkit so we don't get future extraneous messages
            PeerKit.eventBlocks.removeValueForKey(self.sendResultEvent)
            
            NSLog(selfNode.description + " received all \(nodeToResult[sessionUUID]!.count) results for session " + sessionUUID + ".  Merging results.")
            self.fogTool.mergeResults(selfNode, nodeToResult: self.nodeToResult[sessionUUID]!)
            executionTimer.stop()
            
            // remove session information from data structures
            mcPeerIDToNode.removeValueForKey(sessionUUID)
            nodeToWork.removeValueForKey(sessionUUID)
            nodeToResult.removeValueForKey(sessionUUID)
            nodeToRoundTripTimer.removeValueForKey(sessionUUID)
            haveSetUpReprocessWork.removeValueForKey(sessionUUID)
            NSLog("Total execution time: " + String(format: "%.3f", executionTimer.getElapsedTimeInSeconds()) + " seconds.")
        } else {
            // account for timeout failures
            if(haveSetUpReprocessWork[sessionUUID] == false) {
                if(selfNode == callerNode) {
                    NSLog("Setting up reprocessing tasks.")
                    haveSetUpReprocessWork[sessionUUID] = true
                    var averageTimeToFinish:Double = (nodeToRoundTripTimer[sessionUUID]![selfNode]?.getElapsedTimeInSeconds())!
                    var pendingNodes:[Node] = []
                    // get work that has not been completed
                    for (node, work) in nodeToWork[sessionUUID]! {
                        if(node != selfNode) {
                            if(nodeToResult[sessionUUID]!.keys.contains(node) == false) {
                                pendingNodes.append(node)
                            } else {
                                // update running average if needed
                                let nodeCount:Int = nodeToRoundTripTimer[sessionUUID]!.count;
                                averageTimeToFinish = ((Double(nodeCount - 1)*averageTimeToFinish) + (nodeToRoundTripTimer[sessionUUID]![node]?.getElapsedTimeInSeconds())!) / Double(nodeCount)
                            }
                        }
                    }
                    
                    // give peers a little more time to finish, min time to wait is 8 seconds, max time to wait is five minutes.
                    let waitTime:Double = min(max(averageTimeToFinish*0.5, 8), 60*5)
                    var i:Int = 0
                    for node in pendingNodes {
                        let work:FogWork = nodeToWork[sessionUUID]![node]!
        
                        let data:[String:NSObject] =
                            ["FailedPeerID": node.mcPeerID,
                             "FogToolWork": NSKeyedArchiver.archivedDataWithRootObject(work),
                             "SessionID": sessionUUID];
                        
                        let retryTime:Double = waitTime + (averageTimeToFinish*Double(i))
                        NSLog("Scheduling reprocess work for node " + node.description + " in: " + String(format: "%.3f", retryTime) + " seconds.")
                        dispatch_async(dispatch_get_main_queue()) {
                            NSTimer.scheduledTimerWithTimeInterval(retryTime, target: self, selector: #selector(FogMachine.reprocessWork(_:)), userInfo: data, repeats: false)
                        }
                        i = i + 1;
                    }
                }
            }
        }
    }
    
    /**
 
     This method re-processes work on the initiator node that may not come back from other nodes
 
     */
    @objc public func reprocessWork(timer: NSTimer) {
        dispatch_sync(self.lock) {
            
            let dataReceived:[String:NSObject] = timer.userInfo as! [String:NSObject]
            
            let sessionUUID:String = dataReceived["SessionID"] as! String
            if(self.mcPeerIDToNode.keys.contains(sessionUUID)) {
                let failedPeerNode:Node = self.mcPeerIDToNode[sessionUUID]![dataReceived["FailedPeerID"] as! MCPeerID]!
                
                // make sure this thing is still in a failed state!
                if(self.nodeToResult[sessionUUID]!.keys.contains(failedPeerNode) == false) {
                    let work:FogWork = NSKeyedUnarchiver.unarchiveObjectWithData(dataReceived["FogToolWork"] as! NSData) as! FogWork
                
                    NSLog("Processing missing work for node " + failedPeerNode.description)
                    
                    let failedPeerResult:FogResult = self.fogTool.processWork(self.getSelfNode(), fromNode: self.getSelfNode(), work: work)
                
                    // store the result and merge results if needed
                    NSLog("Storing re-processed result.")
                    self.nodeToResult[sessionUUID]![failedPeerNode] = failedPeerResult
                    self.finishAndMerge(self.getSelfNode(), callerNode: self.getSelfNode(), sessionUUID: sessionUUID)
                }
            }
        }
        
        timer.invalidate()
    }
}
