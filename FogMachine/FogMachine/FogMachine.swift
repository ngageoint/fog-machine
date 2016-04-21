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
    private var fmTool: FMTool = FMTool()
    
    // event names to be used with PeerKit
    private let sendWorkEvent: String = "sendWorkEvent"
    // this event name will be concatenated with the session id to allow execute of mulitple session at once
    private let sendResultEvent: String = "sendResultEvent"
    
    private init() {
    }
    
    // get your tool
    public func getTool() -> FMTool {
        return fmTool
    }
    
    // set the tool you want to use with FogMachine
    public func setTool(fmTool: FMTool) {
        self.fmTool = fmTool
        
        // When a peer connects, log the connection and delegate to the tool
        PeerKit.onConnect = { (myPeerID: MCPeerID, peerID: MCPeerID) -> Void in
            let selfNode:FMNode = self.getSelfNode()
            let peerNode:FMNode = FMNode(uniqueId: peerID.displayName.componentsSeparatedByString(PeerKit.ID_DELIMITER)[1], name: peerID.displayName.componentsSeparatedByString(PeerKit.ID_DELIMITER)[0], mcPeerID: peerID)
            
            // make sure this is you!
            //guard myPeerID == selfNode.mcPeerID else { throw FogMachineError.PeerIDError }
            if(myPeerID != selfNode.mcPeerID) {
                NSLog("ERROR: Node id: " + selfNode.mcPeerID.displayName + " does not match peerID: " + myPeerID.displayName + ".")
            }
            
            NSLog(selfNode.description + " connected to " + peerNode.description)
            fmTool.onPeerConnect(selfNode, connectedNode: peerNode)
        }
        
        // When a peer disconnects, log the disconnection and delegate to the tool
        PeerKit.onDisconnect = { (myPeerID: MCPeerID, peerID: MCPeerID) -> Void in
            let selfNode:FMNode = self.getSelfNode()
            let peerNode:FMNode = FMNode(uniqueId: peerID.displayName.componentsSeparatedByString(PeerKit.ID_DELIMITER)[1], name: peerID.displayName.componentsSeparatedByString(PeerKit.ID_DELIMITER)[0], mcPeerID: peerID)
            
            // make sure this is you!
            //guard myPeerID == selfNode.mcPeerID else { throw FogMachineError.PeerIDError }
            if(myPeerID != selfNode.mcPeerID) {
                NSLog("ERROR: Node id: " + selfNode.mcPeerID.displayName + " does not match peerID: " + myPeerID.displayName + ".")
            }
            
            NSLog(peerNode.description + " disconnected from " + selfNode.description)
            fmTool.onPeerDisconnect(selfNode, disconnectedNode: peerNode)
        }
        
        // when a work request comes over the air, have the tool process the work
        PeerKit.eventBlocks[self.sendWorkEvent] = { (fromPeerID: MCPeerID, object: AnyObject?) -> Void in
            let selfNode:FMNode = self.getSelfNode()
            let fromNode:FMNode = FMNode(uniqueId: fromPeerID.displayName.componentsSeparatedByString(PeerKit.ID_DELIMITER)[1], name: fromPeerID.displayName.componentsSeparatedByString(PeerKit.ID_DELIMITER)[0], mcPeerID: fromPeerID)
            
            // deserialize the work
            let dataReceived = NSKeyedUnarchiver.unarchiveObjectWithData(object as! NSData) as! [String: NSObject]
            let sessionUUID:String = dataReceived["SessionID"] as! String
            let peerWork:FMWork =  NSKeyedUnarchiver.unarchiveObjectWithData(dataReceived["FogToolWork"] as! NSData) as! FMWork
            
            let workMirror = Mirror(reflecting: peerWork)
            
            NSLog(selfNode.description + " received \(workMirror.subjectType) to process from " + fromNode.description + " for session " + sessionUUID + ".  Starting to process work.")
            
            // process the work, and get a result
            let processWorkTimer:FMTimer = FMTimer()
            processWorkTimer.start()
            let peerResult:FMResult = self.fmTool.processWork(selfNode, fromNode: fromNode, work: peerWork)
            processWorkTimer.stop()
            
            let dataToSend:[String:NSObject] =
                ["FogToolResult": NSKeyedArchiver.archivedDataWithRootObject(peerResult),
                 "ProcessWorkTime": processWorkTimer.getElapsedTimeInSeconds(),
                 "SessionID": sessionUUID]
            
            let peerResultMirror = Mirror(reflecting: peerResult)
            
            NSLog(selfNode.description + " done processing work.  Sending \(peerResultMirror.subjectType) back.")
            
            // send the result back to the session
            PeerKit.sendEvent(self.sendResultEvent + sessionUUID, object: NSKeyedArchiver.archivedDataWithRootObject(dataToSend), toPeers: [fromPeerID])
        }
    }
    
    // MARK: Properties
    
    public func getSelfNode() -> FMNode {
        return FMNode(uniqueId: PeerKit.myName.componentsSeparatedByString(PeerKit.ID_DELIMITER)[1], name: PeerKit.myName.componentsSeparatedByString(PeerKit.ID_DELIMITER)[0], mcPeerID: PeerKit.masterSession.myPeerId)
    }
    
    public func getPeerNodes() -> [FMNode] {
        var nodes: [FMNode] = []
        
        let mcPeerIDs: [MCPeerID] = PeerKit.masterSession.allConnectedPeers() ?? []
        for peerID in mcPeerIDs {
            nodes.append(FMNode(uniqueId: peerID.displayName.componentsSeparatedByString(PeerKit.ID_DELIMITER)[1], name: peerID.displayName.componentsSeparatedByString(PeerKit.ID_DELIMITER)[0], mcPeerID: peerID))
        }
        nodes.sortInPlace { (obj1, obj2) -> Bool in
            return obj1.uniqueId < obj2.uniqueId
        }
        return nodes
    }
    
    public func getAllNodes() -> [FMNode] {
        var nodes: [FMNode] = []
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
    
    
    // used to time stuff
    // TODO : replace with a better metric utility?
    private let executionTimer:FMTimer = FMTimer()
    
    // how long should the initiator wait after completing it's work to start resechduling work
    private let reprocessingScheduleWaitTimeInSeconds:Double = 5.0
    
    // TODO : Might refactor this into a FogMachineData api ...
    // all the data structures below are session dependant!
    
    // used to control concurrency.  It synchronizes many of the data structures below
    private let lock = dispatch_queue_create("mil.nga.giat.fogmachine", nil)
    
    // keep a map of the session to the MCPeerIDs to the nodes for this session
    private var mcPeerIDToNode:[String:[MCPeerID:FMNode]] = [String:[MCPeerID:FMNode]]()
    
    // keep a map of the session to the Nodes to the works for this session, as nodes may come and go otherwise
    private var nodeToWork:[String:[FMNode:FMWork]] = [String:[FMNode:FMWork]]()
    
    // keep a map of the session to the Nodes to the results for this session, as nodes may come and go otherwise
    private var nodeToResult:[String:[FMNode:FMResult]] = [String:[FMNode:FMResult]]()
    
    // keep a map of the session to the Nodes to the roundTrip time.  The roundtrip time is the time it takes for a node to go out and come back
    private var nodeToRoundTripTimer:[String:[FMNode:FMTimer]] = [String:[FMNode:FMTimer]]()
    
    /**
     
     This runs a FogTool!  Your app should call this!
     
     */
    public func execute() -> Void {
        // time how long the entire execution takes
        executionTimer.start()
        
        // this is a uuid to keep track on this session (a round of execution).  It's mostly used to make sure requests and responses happen correctly for a single session.
        let sessionUUID:String = NSUUID().UUIDString
        
        // create new data structures for this session
        mcPeerIDToNode[sessionUUID] = [MCPeerID:FMNode]()
        nodeToWork[sessionUUID] = [FMNode:FMWork]()
        nodeToResult[sessionUUID] = [FMNode:FMResult]()
        nodeToRoundTripTimer[sessionUUID] = [FMNode:FMTimer]()
        
        for node in getAllNodes() {
            mcPeerIDToNode[sessionUUID]![node.mcPeerID] = node
        }
        
        let numberOfNodes:UInt = UInt(mcPeerIDToNode[sessionUUID]!.count)
        NSLog("Executing " + fmTool.name() + " in session " + sessionUUID + " on \(numberOfNodes) nodes (including myself).")
        
        // when a result comes back over the air for this session
        PeerKit.eventBlocks[self.sendResultEvent + sessionUUID] = { (fromPeerID: MCPeerID, object: AnyObject?) -> Void in
            let selfNode:FMNode = self.getSelfNode()
            
            // deserialize the result!
            let dataReceived:[String: NSObject] = NSKeyedUnarchiver.unarchiveObjectWithData(object as! NSData) as! [String: NSObject]
            let receivedSessionUUID:String = dataReceived["SessionID"] as! String
            let processWorkTime:Double = dataReceived["ProcessWorkTime"] as! Double
            
            // make sure this is the same session!
            if(self.mcPeerIDToNode.keys.contains(receivedSessionUUID)) {
                // store the result and merge results if needed
                dispatch_sync(self.lock) {
                    let fromNode:FMNode = self.mcPeerIDToNode[receivedSessionUUID]![fromPeerID]!
                    let peerResult:FMResult = NSKeyedUnarchiver.unarchiveObjectWithData(dataReceived["FogToolResult"] as! NSData) as! FMResult
                    let peerResultMirror = Mirror(reflecting: peerResult)
                    
                    let roundTripTime:CFAbsoluteTime = (self.nodeToRoundTripTimer[receivedSessionUUID]![fromNode]?.stop())!
                    NSLog(fromNode.description + " round trip time: " + String(format: "%.3f", roundTripTime) + " seconds.")
                    NSLog(fromNode.description + " process work time: " + String(format: "%.3f", processWorkTime) + " seconds.")
                    NSLog(fromNode.description + " network/data transfer and overhead time: " + String(format: "%.3f", roundTripTime - processWorkTime) + " seconds.")
                    NSLog(selfNode.description + " received \(peerResultMirror.subjectType) in session " + receivedSessionUUID + " from " + fromNode.description + " after " + String(format: "%.3f", roundTripTime) + " seconds, storing result.")
                    
                    self.nodeToResult[receivedSessionUUID]![fromNode] = peerResult
                    self.finishAndMerge(fromNode, sessionUUID: receivedSessionUUID)
                }
            } else {
                // the likelyhood of this occuring is very very very small
                NSLog(selfNode.description + " received result for session " + receivedSessionUUID + ", but that session no longer exists.  Discarding work.")
            }
        }
        
        // my work
        var selfWork:FMWork?
        // make the work for each node
        var nodeCount:UInt = 0
        for (mcPeerId, node) in mcPeerIDToNode[sessionUUID]! {
            if(node == getSelfNode()) {
                NSLog("Creating self work.")
            } else {
                NSLog("Creating work for " + node.description)
            }
            let work:FMWork = self.fmTool.createWork(node, nodeNumber: nodeCount, numberOfNodes: numberOfNodes)
            if(node == getSelfNode()) {
                selfWork = work
            }
            nodeToWork[sessionUUID]![node] = work
            nodeToRoundTripTimer[sessionUUID]![node] = FMTimer()
            nodeCount += 1
        }
        
        // send out all the work
        for (node, work) in nodeToWork[sessionUUID]! {
            if(node != getSelfNode()) {
                NSLog("Sending a work to " + node.description)
                
                let data:[String:NSObject] =
                    ["FogToolWork": NSKeyedArchiver.archivedDataWithRootObject(work),
                     "SessionID": sessionUUID]
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
        // FIXME: Make sure this does not block the main thread! do I need to thread this?
        let selfResult:FMResult = self.fmTool.processWork(getSelfNode(), fromNode: getSelfNode(), work: selfWork!)
        
        // store the result and merge results if needed
        dispatch_sync(self.lock) {
            let selfTimeToFinish:Double = (self.nodeToRoundTripTimer[sessionUUID]![self.getSelfNode()]?.stop())!
            NSLog(self.getSelfNode().description + " process work time: " + String(format: "%.3f", selfTimeToFinish) + " seconds.")
            NSLog("Storing self result.")
            self.nodeToResult[sessionUUID]![self.getSelfNode()] = selfResult
            let status = self.finishAndMerge(self.getSelfNode(), sessionUUID: sessionUUID)
            // schedule the reprocessing stuff
            if(status == false) {
                let data:[String:NSObject] = ["SessionID": sessionUUID]
                dispatch_async(dispatch_get_main_queue()) {
                    NSTimer.scheduledTimerWithTimeInterval(self.reprocessingScheduleWaitTimeInSeconds, target: self, selector: #selector(FogMachine.scheduleReprocessWork(_:)), userInfo: data, repeats: false)
                }
            }
        }
    }
    
    /**
     
     This method is called whenever a result comes back.  If all the results have come in, this method will delegate the merge to the FogTool.
     
     @return True if all the results are in and the merge occured, false otherwise
     
     */
    private func finishAndMerge(callerNode:FMNode, sessionUUID:String) -> Bool {
        // TODO : make sure the merge is not called from the UI thread
        
        var status:Bool = false
        // did we get all the results, yet?
        if(nodeToWork[sessionUUID]!.count == nodeToResult[sessionUUID]!.count) {
            // remove sendResultEvent from peerkit for this session so we don't get future extraneous messages that we don't know what do to with
            PeerKit.eventBlocks.removeValueForKey(self.sendResultEvent + sessionUUID)
            
            NSLog(getSelfNode().description + " received all \(nodeToResult[sessionUUID]!.count) results for session " + sessionUUID + ".  Merging results.")
            let mergeResultsTimer:FMTimer = FMTimer()
            mergeResultsTimer.start()
            self.fmTool.mergeResults(getSelfNode(), nodeToResult: self.nodeToResult[sessionUUID]!)
            mergeResultsTimer.stop()
            NSLog("Merge results time for " + fmTool.name() + ": " + String(format: "%.3f", mergeResultsTimer.getElapsedTimeInSeconds()) + " seconds.")
            executionTimer.stop()
            
            // remove session information from data structures
            mcPeerIDToNode.removeValueForKey(sessionUUID)
            nodeToWork.removeValueForKey(sessionUUID)
            nodeToResult.removeValueForKey(sessionUUID)
            nodeToRoundTripTimer.removeValueForKey(sessionUUID)
            NSLog("Total execution time for " + fmTool.name() + ": " + String(format: "%.3f", executionTimer.getElapsedTimeInSeconds()) + " seconds.")
            status = true
        }
        return status
    }
    
    /**
     
     Set up future reprocessing stuff for nodes that might fail
     
     */
    @objc private func scheduleReprocessWork(timer: NSTimer) {
        dispatch_sync(self.lock) {
            let dataReceived:[String:NSObject] = timer.userInfo as! [String:NSObject]
            let sessionUUID:String = dataReceived["SessionID"] as! String
            NSLog("Setting up reprocessing tasks.")
            var totalTimeToFinish:Double = (self.nodeToRoundTripTimer[sessionUUID]![self.getSelfNode()]?.getElapsedTimeInSeconds())!
            var pendingNodes:[FMNode] = []
            // get work that has not been completed
            for (node, work) in self.nodeToWork[sessionUUID]! {
                if(node != self.getSelfNode()) {
                    if(self.nodeToResult[sessionUUID]!.keys.contains(node) == false) {
                        pendingNodes.append(node)
                    } else {
                        // update running average if needed
                        totalTimeToFinish = totalTimeToFinish + (self.nodeToRoundTripTimer[sessionUUID]![node]?.getElapsedTimeInSeconds())!
                    }
                }
            }
            
            let nodeCount:Int = self.nodeToRoundTripTimer[sessionUUID]!.count
            let averageTimeToFinish:Double = totalTimeToFinish/Double(nodeCount)
            
            // give peers 50% more time to finish that the current average time. min time to wait is 8 seconds. max time to wait is 5 minutes.
            let waitTime:Double = min(max((averageTimeToFinish * 0.5) - self.reprocessingScheduleWaitTimeInSeconds, 8), 60*5)
            var i:Int = 0
            for node in pendingNodes {
                let work:FMWork = self.nodeToWork[sessionUUID]![node]!
                
                let data:[String:NSObject] =
                    ["FailedPeerID": node.mcPeerID,
                     "FogToolWork": NSKeyedArchiver.archivedDataWithRootObject(work),
                     "SessionID": sessionUUID]
                
                let selfTimeToFinish:Double = (self.nodeToRoundTripTimer[sessionUUID]![self.getSelfNode()]?.getElapsedTimeInSeconds())!
                let retryTime:Double = waitTime + (selfTimeToFinish*Double(i))
                NSLog("Scheduling reprocess work for node " + node.description + " in: " + String(format: "%.3f", retryTime) + " seconds.")
                dispatch_async(dispatch_get_main_queue()) {
                    NSTimer.scheduledTimerWithTimeInterval(retryTime, target: self, selector: #selector(FogMachine.reprocessWork(_:)), userInfo: data, repeats: false)
                }
                i = i + 1
            }
        }
    }
    
    /**
     
     This method re-processes work on the initiator node that may not come back from other nodes
     
     */
    @objc private func reprocessWork(timer: NSTimer) {
        dispatch_sync(self.lock) {
            let dataReceived:[String:NSObject] = timer.userInfo as! [String:NSObject]
            let sessionUUID:String = dataReceived["SessionID"] as! String
            if(self.mcPeerIDToNode.keys.contains(sessionUUID)) {
                let failedPeerNode:FMNode = self.mcPeerIDToNode[sessionUUID]![dataReceived["FailedPeerID"] as! MCPeerID]!
                
                // make sure this thing is still in a failed state!
                if(self.nodeToResult[sessionUUID]!.keys.contains(failedPeerNode) == false) {
                    let work:FMWork = NSKeyedUnarchiver.unarchiveObjectWithData(dataReceived["FogToolWork"] as! NSData) as! FMWork
                    
                    NSLog("Processing missing work for node " + failedPeerNode.description)
                    
                    let peerResult:FMResult = self.fmTool.processWork(self.getSelfNode(), fromNode: self.getSelfNode(), work: work)
                    
                    // store the result and merge results if needed
                    NSLog("Storing re-processed result.")
                    self.nodeToResult[sessionUUID]![failedPeerNode] = peerResult
                    self.finishAndMerge(self.getSelfNode(), sessionUUID: sessionUUID)
                } else {
                    NSLog("No need to re-processed " + failedPeerNode.description + " work.  Work was returned.")
                }
            } else {
                NSLog("No need to re-processed work, work came back and session completed.")
            }
        }
        
        timer.invalidate()
    }
}
