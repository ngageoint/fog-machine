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
    
    // used to control concurrency
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
                NSLog("ERROR: Node id: " + selfNode.mcPeerID.displayName + " does not match peerID: " + myPeerID.displayName)
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
                NSLog("ERROR: Node id: " + selfNode.mcPeerID.displayName + " does not match peerID: " + myPeerID.displayName)
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
    
    /**
     
     This runs a FogTool!  Your app should call this!
     
     */
    public func execute() -> Void {
        // time how long the entire execution takes
        executionTimer.start()
        
        // this is a uuid to keep track on this session (a round of execution).  It's mostly used to make sure requests and responses happen correctly for a single session.
        let sessionUUID:String = NSUUID().UUIDString
        
        // keep a map of MCPeerIDs to the nodes for this session
        var mcPeerIDToNode:[MCPeerID:Node] = [MCPeerID:Node]()
        
        for node in getAllNodes() {
            mcPeerIDToNode[node.mcPeerID] = node;
        }
        
        NSLog("Executing " + fogTool.name() + " in session " + sessionUUID + " on \(mcPeerIDToNode.count) nodes (including myself)")
        
        // keep a map of the Nodes to the works for this session, as nodes may come and go otherwise
        var nodeToWork:[Node:FogWork] = [Node:FogWork]()
        
        // keep a map of the Nodes to the results for this session, as nodes may come and go otherwise
        var nodeToResult:[Node:FogResult] = [Node:FogResult]()
        
        
        // when a result comes back over the air
        PeerKit.eventBlocks[self.sendResultEvent] = { (fromPeerID: MCPeerID, object: AnyObject?) -> Void in
            let selfNode: Node = self.getSelfNode()
            let fromNode: Node = mcPeerIDToNode[fromPeerID]!
            
            // deserialize the result!
            let dataReceived = NSKeyedUnarchiver.unarchiveObjectWithData(object as! NSData) as! [String: NSObject]
            let receivedSessionUUID:String = dataReceived["SessionID"] as! String
            
            // make sure this is the same session!
            if(receivedSessionUUID == sessionUUID) {
                let peerResult:FogResult = NSKeyedUnarchiver.unarchiveObjectWithData(dataReceived["FogToolResult"] as! NSData) as! FogResult
                let peerResultMirror = Mirror(reflecting: peerResult)
                
                // store the result and merge results if needed
                dispatch_sync(self.lock) {
                    NSLog(selfNode.description + " received \(peerResultMirror.subjectType) in session " + receivedSessionUUID + " from " + fromNode.description + ", storing result.")
                    nodeToResult[fromNode] = peerResult
                    self.finishAndMerge(selfNode, nodeToWork: nodeToWork, nodeToResult: nodeToResult, sessionUUID: receivedSessionUUID)
                }
            } else {
                NSLog(selfNode.description + " received result for session " + receivedSessionUUID + ", but new session " + sessionUUID + " is underway.  Discarding work.")
            }
        }
        
        // my work
        var selfWork:FogWork?
        // make the work for each node
        var works :[FogWork] = []
        
        var nodeCount:UInt = 0
        let numberOfNodes:UInt = UInt(mcPeerIDToNode.count)
        for (mcPeerId, node) in mcPeerIDToNode {
            if(node == getSelfNode()) {
                NSLog("Creating self work")
            } else {
                NSLog("Creating work for " + node.description)
            }
            let work:FogWork = self.fogTool.createWork(node, nodeNumber: nodeCount, numberOfNodes: numberOfNodes)
            if(node == getSelfNode()) {
                selfWork = work
            }
            nodeToWork[node] = work
            nodeCount += 1
        }
        
        // send out all the work
        for (node, work) in nodeToWork {
            if(node != getSelfNode()) {
                NSLog("Sending a work to " + node.description)
                
                let data:[String:NSObject] =
                ["FogToolWork": NSKeyedArchiver.archivedDataWithRootObject(work),
                 "SessionID": sessionUUID];
                
                PeerKit.sendEvent(self.sendWorkEvent, object: NSKeyedArchiver.archivedDataWithRootObject(data), toPeers: [node.mcPeerID])
            }
        }
        
        // process your own work
        NSLog("Processing self work.")
        let selfResult:FogResult = self.fogTool.processWork(getSelfNode(), fromNode: getSelfNode(), work: selfWork!)
        
        // store the result and merge results if needed
        dispatch_sync(self.lock) {
            NSLog("Storing self result.")
            nodeToResult[self.getSelfNode()] = selfResult
            self.finishAndMerge(self.getSelfNode(), nodeToWork: nodeToWork, nodeToResult: nodeToResult, sessionUUID: sessionUUID)
        }
    }
    
    private func finishAndMerge(selfNode:Node, nodeToWork:[Node:FogWork], nodeToResult:[Node:FogResult], sessionUUID:String) {
        // did we get all the results, yet?
        if(nodeToWork.count == nodeToResult.count) {
            // remove sendResultEvent from peerkit so we don't get future extraneous messages
            PeerKit.eventBlocks.removeValueForKey(self.sendResultEvent)
            
            NSLog(selfNode.description + " received all \(nodeToResult.count) results.  Merging results.")
            self.fogTool.mergeResults(selfNode, nodeToResult: nodeToResult)
            executionTimer.stop()
            NSLog("Execution time: " + String(format: "%.3f", executionTimer.getElapsedTimeInSeconds()) + " seconds")
        } else {
            // TODO: account for timeout failures
            
//            var pendingNodes:[Node] = []
//            // get work that has not been completed
//            for (node, work) in nodeToWork {
//                if(node != selfNode) {
//                    if(!nodeToResult.keys.contains(node)) {
//                        pendingNodes.append(node)
//                    }
//                }
//            }
//
//            for node in pendingNodes {
//                var work:FogWork = nodeToWork[node]!
//                
//                let data:[String:NSObject] =
//                    ["failedPeerID": node.mcPeerID,
//                     "work": work.getDataToSerialize(),
//                     "SessionID": sessionUUID];
//                
//                NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: #selector(FogMachine.reprocessWork(_:)), userInfo: work, repeats: false)
//            }
        }
    }
    
//    public func reprocessWork(timer: NSTimer) {
//        NSLog("Processing missing work.")
//        let data:[String:NSObject] = timer.userInfo as! [String:NSObject]
//        
//        let work:FogWork = data["work"] as! [String:NSObject]
//        
//        let selfResult:FogResult = self.fogTool.processWork(getSelfNode(), fromNode: getSelfNode(), work: work)
//        
//        // store the result and merge results if needed
//            NSLog("Storing self result.")
//            nodeToResult[self.getSelfNode()] = selfResult
//            self.finishAndMerge(self.getSelfNode(), nodeToWork: nodeToWork, nodeToResult: nodeToResult)
//        
//        timer.invalidate()
//    }

    
    //
    //
    //    public func processResult(event: String, responseEvent: String, sender: MCPeerID, object: [String: MPCSerializable]) {
    //        //dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
    //        let senderNode = Node(mcPeerId: sender)
    //        dispatch_barrier_async(self.serialQueue) {
    //            fogMetrics.startForMetric(Fog.Metric.RECEIVE, deviceNode: senderNode)
    //            self.fogTool.processResult(result: object, fromPeerId: sender)
    //            self.printOut("processResult from \(sender)")
    //            self.receiptAssurance.updateForReceipt(responseEvent, receiver: senderNode)
    //
    //            //  dispatch_async(dispatch_get_main_queue()) {
    //            fogMetrics.stopForMetric(Fog.Metric.RECEIVE, deviceNode: senderNode)
    //            if self.receiptAssurance.checkAllReceived(responseEvent) {
    //                self.printOut("Running completeMethod()")
    //                self.fogTool.completeWork()
    //                self.receiptAssurance.removeAllForEvent(responseEvent)
    //            } else if self.receiptAssurance.checkForTimeouts(responseEvent) {
    //                self.printOut("Timeout found")
    //                self.reprocessWork(responseEvent)
    //            } else {
    //                self.printOut("Not done and no timeouts yet.")
    //            }
    //        }
    //    }
    
    
    //
    //    public func sendEventToAll(event: String, timeoutSeconds: Double = 30.0, metadata: AnyObject)
    //    {
    //        var hasPeers = false
    //        var deviceCounter = 1
    //        let selfWork = self.fogTool.workDivider(currentQuadrant: deviceCounter, numberOfQuadrants: ConnectionManager.allNodes().count, metadata: metadata)
    //        self.receiptAssurance.add(ConnectionManager.selfNode(), event: event, work: selfWork, timeoutSeconds: timeoutSeconds)
    //
    //        // The barrier is used to sync sends to receipts and prevent a really fast device from finishing and sending results back before any other device has been sent their results, causing the response queue to only have one sent entry
    //        // The processResult function uses the same barrier so the first result is not processed until all the Work has been sent out
    //        dispatch_barrier_async(self.serialQueue) {
    //            for peer in ConnectionManager.allPeerIDs() {
    //                hasPeers = true
    //                deviceCounter = deviceCounter + 1
    //                let peerNode = Node(mcPeerId: peer)
    //                fogMetrics.startForMetric(Fog.Metric.SEND, deviceNode: peerNode)
    //                let theWork = self.fogTool.workDivider(currentQuadrant: deviceCounter, numberOfQuadrants: ConnectionManager.allNodes().count, metadata: metadata)
    //                theWork.workerNode = Node(mcPeerId: peer)
    //
    //                self.receiptAssurance.add(peerNode, event: event, work: theWork, timeoutSeconds:  timeoutSeconds)
    //
    //                self.sendEventTo(event, object: [event: theWork], sendTo: peer.displayName)
    //                self.fogTool.log(peerName: peer.displayName)
    //                fogMetrics.stopForMetric(Fog.Metric.SEND, deviceNode: peerNode)
    //            }
    //        }
    //        receiptAssurance.startTimer(event, timeoutSeconds: timeoutSeconds, reprocessMethod: ConnectionManager.reprocessWork(self))
    //        dispatch_barrier_async(self.serialQueue) {
    //
    //        self.fogTool.selfWork(selfWork: selfWork, hasPeers: hasPeers)
    //        self.receiptAssurance.updateForReceipt(event, receiver: ConnectionManager.selfNode())
    //        }
    //    }
    //
    //
    //    public func checkForTimeouts(responseEvent: String) {
    //        printOut("timer in ConnectionManager")
    //
    //        while receiptAssurance.checkForTimeouts(responseEvent) {
    //            printOut("detected timed out work")
    //            self.reprocessWork(responseEvent)
    //        }
    //    }
    //
    //
    //    public func reprocessWork(responseEvent: String) {
    //        let peer = receiptAssurance.getFinishedPeer(responseEvent)
    //        let work = receiptAssurance.getNextTimedOutWork(responseEvent)
    //        if let timedOutWork = work {
    //            self.printOut("Found work to finish")
    //            if !peer.isSelf() {
    //                self.printOut("Found peer \(peer.displayName) to finish work")
    //                self.sendEventTo(responseEvent, object: [responseEvent: timedOutWork], sendTo: (peer.displayName + PeerKit.ID_DELIMITER + peer.uniqueId))
    //            } else if peer.isSelf() {
    //                self.fogTool.selfWork(selfWork: timedOutWork, hasPeers: true)
    //                // Handle situation when all peers are done and only the initiator is processing work.
    //                //   Once done, the initiator needs to call complete.
    //                if receiptAssurance.checkAllReceived(responseEvent) {
    //                    printOut("Running completeMethod()")
    //                    self.fogTool.completeWork()
    //                    receiptAssurance.removeAllForEvent(responseEvent)
    //                }
    //            }
    //        }
    //    }
}
