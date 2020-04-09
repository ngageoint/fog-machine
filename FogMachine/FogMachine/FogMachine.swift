import Foundation
import MultipeerConnectivity

/**

 To utilize the FogMachine framework, your app should interface with this class.  It will handle the network connections and the distribution of processing.

 This class, FogMachine, is a singleton! Please use it as such.  Extend FogTool and pass an instance into this class using setTool().

 Example:
 
     // What do I need help with?  How about saying hello?
     public class HelloWorldTool : FMTool {
         public override func createWork(node:FMNode, nodeNumber:UInt, numberOfNodes:UInt) -> HelloWorldWork {
             return HelloWorldWork(nodeNumber: nodeNumber)
         }
         
         public override func processWork(node:FMNode, fromNode:FMNode, work: FMWork) -> HelloWorldResult {
             let helloWorldWork:HelloWorldWork = work as! HelloWorldWork
             print("Hello world, this is node \(helloWorldWork.nodeNumber).")
             return HelloWorldResult(didSayHello: true)
         }
         
         public override func mergeResults(node:FMNode, nodeToResult: [FMNode:FMResult]) -> Void {
             var totalNumberOfHellos:Int = 0
             for (n, result) in nodeToResult {
                 let helloWorldResult = result as! HelloWorldResult
                 if(helloWorldResult.didSayHello) {
                     totalNumberOfHellos += 1
                 }
             }
             print("Said hello \(totalNumberOfHellos) times.  It's a good day. :)")
         }
     }
     
     
     // Tell Fog Machine what we need help with
     FogMachine.fogMachineInstance.setTool(HelloWorldTool())
     
     // Look for friends/devices to help me
     FogMachine.fogMachineInstance.startSearchForPeers()
     
     // Run HelloWorldTool on all the nodes in the Fog Machine mesh-network and say hello to everyone!
     FogMachine.fogMachineInstance.execute()
 
 */
public class FogMachine {

    /// The singleton instance of FogMachine.  Ex: FogMachine.fogMachineInstance.execute()
    public static let fogMachineInstance = FogMachine()

    // Your application will set this
    private var fmTool: FMTool = FMTool()

    // event names to be used with PeerPack
    // this event name will be concatenated with the tool id.  This makes sure peers only offer help for the same tools.
    private let sendWorkEvent: String = "sendWorkEvent"
    // this event name will be concatenated with the session id.  This allows execution of mulitple session at once.
    private let sendResultEvent: String = "sendResultEvent"

    private init() {
    }

    /**
     Get the `FMTool` you set with setTool().
     
     - returns: FMTool
     */
    public func getTool() -> FMTool {
        return fmTool
    }

    /**
     
     Set the `FMTool` you want to use with FogMachine
     
     - parameter fmTool: The tool you want to use with FogMachine.
     
     */
    public func setTool(fmTool: FMTool) {
        self.fmTool = fmTool

        // When a peer connects, log the connection and delegate to the tool
        PeerPack.onConnect = { (myPeerID: MCPeerID, peerID: MCPeerID) -> Void in
            let selfNode:FMNode = self.getSelfNode()
            let peerNode:FMNode = FMNode(uniqueId: peerID.displayName.components(separatedBy: PeerPack.ID_DELIMITER)[1], name: peerID.displayName.components(separatedBy: PeerPack.ID_DELIMITER)[0], mcPeerID: peerID)

            // make sure this is you!
            //guard myPeerID == selfNode.mcPeerID else { throw FogMachineError.PeerIDError }
            if(myPeerID != selfNode.mcPeerID) {
                self.FMLog(format: "ERROR: Node id: " + selfNode.mcPeerID.displayName + " does not match peerID: " + myPeerID.displayName + ".")
            }

            self.FMLog(format: selfNode.description + " connected to " + peerNode.description)
            fmTool.onPeerConnect(myNode: selfNode, connectedNode: peerNode)
        }

        // When a peer disconnects, log the disconnection and delegate to the tool
        PeerPack.onDisconnect = { (myPeerID: MCPeerID, peerID: MCPeerID) -> Void in
            let selfNode:FMNode = self.getSelfNode()
            let peerNode:FMNode = FMNode(uniqueId: peerID.displayName.components(separatedBy: PeerPack.ID_DELIMITER)[1], name: peerID.displayName.components(separatedBy: PeerPack.ID_DELIMITER)[0], mcPeerID: peerID)

            // make sure this is you!
            //guard myPeerID == selfNode.mcPeerID else { throw FogMachineError.PeerIDError }
            if(myPeerID != selfNode.mcPeerID) {
                self.FMLog(format: "ERROR: Node id: " + selfNode.mcPeerID.displayName + " does not match peerID: " + myPeerID.displayName + ".")
            }

            self.FMLog(format: peerNode.description + " disconnected from " + selfNode.description)
            fmTool.onPeerDisconnect(myNode: selfNode, disconnectedNode: peerNode)
        }

        // when a work request comes over the air, have the tool process the work
        PeerPack.eventBlocks[self.sendWorkEvent + String(fmTool.id())] = { (fromPeerID: MCPeerID, object: AnyObject?) -> Void in
            // run on background thread
            DispatchQueue.global(qos: .utility).async {
                let selfNode:FMNode = self.getSelfNode()
                let fromNode:FMNode = FMNode(uniqueId: fromPeerID.displayName.components(separatedBy: PeerPack.ID_DELIMITER)[1], name: fromPeerID.displayName.components(separatedBy: PeerPack.ID_DELIMITER)[0], mcPeerID: fromPeerID)

                // deserialize the work
                let dataReceived = NSKeyedUnarchiver.unarchiveObject(with: object as! Data) as! [String: Any]
                let sessionUUID:String = dataReceived["SessionID"] as! String
                let peerWork:FMWork =  NSKeyedUnarchiver.unarchiveObject(with: dataReceived["FogToolWork"] as! Data) as! FMWork

                let workMirror = Mirror(reflecting: peerWork)

                self.FMLog(format: selfNode.description + " received \(workMirror.subjectType) to process from " + fromNode.description + " for session " + sessionUUID + ".  Starting to process work.")

                // process the work, and get a result
                let processWorkTimer:FMTimer = FMTimer()
                processWorkTimer.start()
                let peerResult:FMResult = self.fmTool.processWork(node: selfNode, fromNode: fromNode, work: peerWork)
                processWorkTimer.stop()

                let dataToSend:[String:Any] =
                    ["FogToolResult": NSKeyedArchiver.archivedData(withRootObject: peerResult),
                     "ProcessWorkTime": processWorkTimer.getElapsedTimeInSeconds(),
                     "SessionID": sessionUUID]

                let peerResultMirror = Mirror(reflecting: peerResult)

                self.FMLog(format: selfNode.description + " done processing work.  Sending \(peerResultMirror.subjectType) back.")

                // send the result back to the session
                PeerPack.sendEvent(event: self.sendResultEvent + sessionUUID, object: NSKeyedArchiver.archivedData(withRootObject: dataToSend), toPeers: [fromPeerID])
                self.FMLog(format: "Sent result.")
            }
        }
    }

    /**
     
     Returns information about this particular device.
     
     - returns: The FMNode that is your device.
     
     */
    public func getSelfNode() -> FMNode {
        return FMNode(uniqueId: PeerPack.myName.components(separatedBy: PeerPack.ID_DELIMITER)[1], name: PeerPack.myName.components(separatedBy: PeerPack.ID_DELIMITER)[0], mcPeerID: PeerPack.masterSession.myPeerId)
    }

    /**
     
     Returns information about the other nodes in the current network that can provide help.
     
     - returns: Array of FMNode that can provide help.
     
     */
    public func getPeerNodes() -> [FMNode] {
        var nodes: [FMNode] = []

        let mcPeerIDs: [MCPeerID] = PeerPack.masterSession.allConnectedPeers() ?? []
        for peerID in mcPeerIDs {
            nodes.append(FMNode(uniqueId: peerID.displayName.components(separatedBy: PeerPack.ID_DELIMITER)[1], name: peerID.displayName.components(separatedBy: PeerPack.ID_DELIMITER)[0], mcPeerID: peerID))
        }
        nodes.sort { (obj1, obj2) -> Bool in
            return obj1.uniqueId < obj2.uniqueId
        }
        return nodes
    }

    /**
     
     All Nodes
     
     - returns: All nodes (including yourself) in the current network.
     
     */
    public func getAllNodes() -> [FMNode] {
        var nodes: [FMNode] = []
        nodes.append(getSelfNode())
        nodes += getPeerNodes()
        nodes.sort { (obj1, obj2) -> Bool in
            return obj1.uniqueId < obj2.uniqueId
        }
        return nodes
    }

    /**
     
     Tell FogMachine to start looking for peers to help with your tool.  Only peers with the same tool set can provide help. See the README for more information.
     
     */
    public func startSearchForPeers() {
        // Service type can contain only ASCII lowercase letters, numbers, and hyphens.
        // It must be a unique string, at most 15 characters long
        // Note: Devices will only connect to other devices with the same serviceType value.
        let SERVICE_TYPE = "FM" + String(fmTool.id())
        self.FMLog(format: "Searching for peers with service type " + SERVICE_TYPE)
        PeerPack.transceiver.startTransceiving(serviceType: SERVICE_TYPE)
    }


    // used to time stuff
    private let executionTimer:FMTimer = FMTimer()
    
    // the shortest time in seconds that FogMachine should wait before re-processing other nodes work.  The initiator will wait after completing it's work to start resechduling work.
    private var minWaitTimeToStartReprocessingWorkInSeconds:Double = 8.0
    
    // the longest time in seconds that Fog Machine should wait before re-processing other nodes work.  The initiator will wait after completing it's work to start resechduling work.
    private var maxWaitTimeToStartReprocessingWorkInSeconds:Double = 60.0*5.0
    
    /**
     The shortest time in seconds that FogMachine should wait before re-processing other nodes work.  (The default is set to 8 seconds)  The initiator will wait after completing it's work to start resechduling work.  Unless strict is set to true, Fog Machine will wait a bit longer to start reprocessing work based on the performance of the nodes in the network.
     
     - parameter time:   the shortest time in seconds that FogMachine should wait before re-processing other nodes work.
     - parameter strict: if true, the time provided as the first argument will be the exact time that re-processing the other nodes work begins.
     */
    public func setWaitTimeUntilStartReprocessingWork(time:Double, strict:Bool = false) {
        minWaitTimeToStartReprocessingWorkInSeconds = max(time,0)
        if(strict) {
            maxWaitTimeToStartReprocessingWorkInSeconds = max(time,0)
        }
    }

    // all the data structures below are session dependant!
    // used to control concurrency.  It synchronizes many of the data structures below
    private let lock = DispatchQueue(label: "mil.nga.giat.fogmachine")

    // keep a map of the session to the MCPeerIDs to the nodes for this session
    private var mcPeerIDToNode:[String:[MCPeerID:FMNode]] = [String:[MCPeerID:FMNode]]()

    // keep a map of the session to the Nodes to the works for this session, as nodes may come and go otherwise
    private var nodeToWork:[String:[FMNode:FMWork]] = [String:[FMNode:FMWork]]()

    // keep a map of the session to the Nodes to the results for this session, as nodes may come and go otherwise
    private var nodeToResult:[String:[FMNode:FMResult]] = [String:[FMNode:FMResult]]()

    // keep a map of the session to the Nodes to the roundTrip time.  The roundtrip time is the time it takes for a node to go out and come back
    private var nodeToRoundTripTimer:[String:[FMNode:FMTimer]] = [String:[FMNode:FMTimer]]()


    /**

    Runs your FMTool.  Your app should call this.

     */
    public func execute() -> Void {
        // run on background thread
        DispatchQueue.global(qos: .utility).async {
            self.executeOnThread(onNodes: self.getAllNodes())
        }
    }
    
    /**
     Runs your FMTool on a subset of the nodes in the network.  Your app should call this or execute().
     
     - parameter onNodes: A subset of the nodes in your network that should run your tool.
     */
    public func execute(onNodes:[FMNode]) -> Void {
        
        // make sure the nodes your app passed in are actually still in the network
        var nodesInNetwork:[FMNode] = []
        for n in onNodes {
            if(self.getAllNodes().contains(n)) {
                nodesInNetwork.append(n)
            } else {
                FMLog(format: "Network does not contain node \(n.description).  Excluding this node from execution.")
            }
        }
        
        // run on background thread
        DispatchQueue.global(qos: .utility).async {
            self.executeOnThread(onNodes: nodesInNetwork)
        }
    }

    /**
     
     Runs your FMTool.
     
     */
    private func executeOnThread(onNodes:[FMNode]) -> Void {
        // time how long the entire execution takes
        executionTimer.start()

        // this is a uuid to keep track on this session (a round of execution).  It's mostly used to make sure requests and responses happen correctly for a single session.
        let sessionUUID:String = UUID().uuidString

        // create new data structures for this session
        mcPeerIDToNode[sessionUUID] = [MCPeerID:FMNode]()
        nodeToWork[sessionUUID] = [FMNode:FMWork]()
        nodeToResult[sessionUUID] = [FMNode:FMResult]()
        nodeToRoundTripTimer[sessionUUID] = [FMNode:FMTimer]()

        for node in onNodes {
            mcPeerIDToNode[sessionUUID]![node.mcPeerID] = node
        }

        let numberOfNodes:UInt = UInt(mcPeerIDToNode[sessionUUID]!.count)
        self.FMLog(format: "Executing " + fmTool.name() + " in session " + sessionUUID + " on \(numberOfNodes) nodes (including myself).")

        // when a result comes back over the air for this session
        PeerPack.eventBlocks[self.sendResultEvent + sessionUUID] = { (fromPeerID: MCPeerID, object: AnyObject?) -> Void in
            let selfNode:FMNode = self.getSelfNode()

            // deserialize the result!
            let dataReceived:[String: NSObject] = NSKeyedUnarchiver.unarchiveObject(with: object as! Data) as! [String: NSObject]
            let receivedSessionUUID:String = dataReceived["SessionID"] as! String
            let processWorkTime:Double = dataReceived["ProcessWorkTime"] as! Double

            // make sure this is the same session!
            if(self.mcPeerIDToNode.keys.contains(receivedSessionUUID)) {
                // store the result and merge results if needed
                self.lock.sync {
                    let fromNode:FMNode = self.mcPeerIDToNode[receivedSessionUUID]![fromPeerID]!
                    let peerResult:FMResult = NSKeyedUnarchiver.unarchiveObject(with: dataReceived["FogToolResult"] as! Data) as! FMResult
                    let peerResultMirror = Mirror(reflecting: peerResult)

                    let roundTripTime:CFAbsoluteTime = (self.nodeToRoundTripTimer[receivedSessionUUID]![fromNode]?.stop())!
                    self.FMLog(format: selfNode.description + " received \(peerResultMirror.subjectType) in session " + receivedSessionUUID + " from " + fromNode.description + ", storing result.")
                    self.FMLog(format: fromNode.description + " round trip time: " + String(format: "%.3f", roundTripTime) + " seconds.")
                    self.FMLog(format: fromNode.description + " process work time: " + String(format: "%.3f", processWorkTime) + " seconds.")
                    self.FMLog(format: fromNode.description + " network/data transfer and overhead time: " + String(format: "%.3f", roundTripTime - processWorkTime) + " seconds.")

                    self.nodeToResult[receivedSessionUUID]![fromNode] = peerResult
                    self.finishAndMerge(callerNode: fromNode, sessionUUID: receivedSessionUUID)
                }
            } else {
                // the likelyhood of this occuring is small.
                self.FMLog(format: selfNode.description + " received result for session " + receivedSessionUUID + ", but that session no longer exists.  Discarding work.")
            }
        }

        // my work
        var selfWork:FMWork?
        // make the work for each node
        var nodeCount:UInt = 0
        for (_, node) in mcPeerIDToNode[sessionUUID]! {
            if(node == getSelfNode()) {
                self.FMLog(format: "Creating self work.")
            } else {
                self.FMLog(format: "Creating work for " + node.description)
            }
            let work:FMWork = self.fmTool.createWork(node: node, nodeNumber: nodeCount, numberOfNodes: numberOfNodes)
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
                self.FMLog(format: "Sending work to " + node.description)

                let data:[String:Any] =
                    ["FogToolWork": NSKeyedArchiver.archivedData(withRootObject: work),
                     "SessionID": sessionUUID]
                self.lock.sync {
                    self.nodeToRoundTripTimer[sessionUUID]![node]?.start()
                }
                PeerPack.sendEvent(event: self.sendWorkEvent + String(fmTool.id()), object: NSKeyedArchiver.archivedData(withRootObject: data), toPeers: [node.mcPeerID])
            }
        }

        var selfResult:FMResult?
        if(selfWork != nil) {
            // process your own work
            self.FMLog(format: "Processing self work.")
            self.lock.sync {
                self.nodeToRoundTripTimer[sessionUUID]![self.getSelfNode()]?.start()
            }
        
            selfResult = self.fmTool.processWork(node: getSelfNode(), fromNode: getSelfNode(), work: selfWork!)
        }

        // store the result and merge results if needed
        self.lock.sync {
            var selfTimeToFinish:Double = 0
            if(selfResult != nil) {
                selfTimeToFinish = (self.nodeToRoundTripTimer[sessionUUID]![self.getSelfNode()]?.stop())!
                self.FMLog(format: self.getSelfNode().description + " process work time: " + String(format: "%.3f", selfTimeToFinish) + " seconds.")
                self.FMLog(format: "Storing self work result.")
                self.nodeToResult[sessionUUID]![self.getSelfNode()] = selfResult!
            }
            let status = self.finishAndMerge(callerNode: self.getSelfNode(), sessionUUID: sessionUUID)
            // schedule the reprocessing stuff
            if(status == false) {
                let data:[String:Any] = ["SessionID": sessionUUID, "SelfTimeToFinish":selfTimeToFinish]
                DispatchQueue.main.async {
                    // wait the minTime before startinf to reprocess
                    Timer.scheduledTimer(timeInterval: self.minWaitTimeToStartReprocessingWorkInSeconds, target: self, selector: #selector(FogMachine.scheduleReprocessWork(_:)), userInfo: data, repeats: false)
                }
            }
        }
    }
    
    /**
     
     This method is called whenever a result comes in on the network (or from yourself).  If all the results have come in, this method will delegate the merge to the FogTool.
     
     - parameter callerNode:  The node that returned the FMresult that resulted in this call
     - parameter sessionUUID: The session that this information is for
     
     - returns: true if all the results are in and the merge occured, false otherwise
     
     */
    private func finishAndMerge(callerNode:FMNode, sessionUUID:String) -> Bool {
        var status:Bool = false
        // did we get all the results, yet?
        if(nodeToWork[sessionUUID]!.count == nodeToResult[sessionUUID]!.count) {
            // remove sendResultEvent from peerpack for this session so we don't get future extraneous messages that we don't know what do to with
            PeerPack.eventBlocks.removeValue(forKey: self.sendResultEvent + sessionUUID)

            self.FMLog(format: getSelfNode().description + " received all \(nodeToResult[sessionUUID]!.count) results for session " + sessionUUID + ".  Merging results.")
            let mergeResultsTimer:FMTimer = FMTimer()
            mergeResultsTimer.start()
            self.fmTool.mergeResults(node: getSelfNode(), nodeToResult: self.nodeToResult[sessionUUID]!)
            mergeResultsTimer.stop()
            self.FMLog(format: "Merge results time for " + fmTool.name() + ": " + String(format: "%.3f", mergeResultsTimer.getElapsedTimeInSeconds()) + " seconds.")
            executionTimer.stop()

            // remove session information from data structures
            mcPeerIDToNode.removeValue(forKey: sessionUUID)
            nodeToWork.removeValue(forKey: sessionUUID)
            nodeToResult.removeValue(forKey: sessionUUID)
            nodeToRoundTripTimer.removeValue(forKey: sessionUUID)
            self.FMLog(format: "Total execution time for " + fmTool.name() + ": " + String(format: "%.3f", executionTimer.getElapsedTimeInSeconds()) + " seconds.")
            status = true
        }
        return status
    }

    /**
     
     Set up future reprocessing stuff for nodes that might fail
     
     - parameter timer: <#timer description#>
     
     */
    @objc private func scheduleReprocessWork(_ timer: Timer) {
        self.lock.sync {
            let dataReceived:[String:NSObject] = timer.userInfo as! [String:NSObject]
            let sessionUUID:String = dataReceived["SessionID"] as! String
            let selfTimeToFinish:Double = dataReceived["SelfTimeToFinish"] as! Double
            // does the session still exist?
            if(self.mcPeerIDToNode.keys.contains(sessionUUID)) {
                self.FMLog(format: "Setting up reprocessing tasks.")
                var totalTimeToFinish:Double = 0
                totalTimeToFinish += selfTimeToFinish
                var pendingNodes:[FMNode] = []
                // get work that has not been completed
                for (node, _) in self.nodeToWork[sessionUUID]! {
                    if(node != self.getSelfNode()) {
                        if(self.nodeToResult[sessionUUID]!.keys.contains(node) == false) {
                            pendingNodes.append(node)
                        } else {
                            // update running average if needed
                            if(self.nodeToRoundTripTimer.keys.contains(sessionUUID)) {
                                totalTimeToFinish += (self.nodeToRoundTripTimer[sessionUUID]![node]?.getElapsedTimeInSeconds())!
                            }
                        }
                    }
                }

                let nodeCount:Int = self.nodeToRoundTripTimer[sessionUUID]!.count
                let averageTimeToFinish:Double = totalTimeToFinish/Double(nodeCount)

                // give peers 40% more time to finish that the current average time.
                let waitTime:Double = min(max(((averageTimeToFinish * 1.4) - selfTimeToFinish) - self.minWaitTimeToStartReprocessingWorkInSeconds, 0), self.maxWaitTimeToStartReprocessingWorkInSeconds)
                var i:Int = 0
                for node in pendingNodes {
                    let work:FMWork = self.nodeToWork[sessionUUID]![node]!

                    let data:[String:Any] =
                        ["FailedPeerID": node.mcPeerID,
                         "FogToolWork": NSKeyedArchiver.archivedData(withRootObject: work),
                         "SessionID": sessionUUID]

                    let retryTime:Double = waitTime + (selfTimeToFinish*Double(i))
                    self.FMLog(format: "Scheduling reprocess work for node " + node.description + " in: " + String(format: "%.3f", retryTime) + " seconds.")
                    DispatchQueue.main.async {
                        Timer.scheduledTimer(timeInterval: retryTime, target: self, selector: #selector(FogMachine.reprocessWork(_:)), userInfo: data, repeats: false)
                    }
                    i += 1
                }
            }
        }
    }

    /**
     
     This method re-processes work on the initiator node that may not come back from other nodes
     
     - parameter timer: <#timer description#>
     
     */
    @objc private func reprocessWork(_ timer: Timer) {
        self.lock.sync {
            let dataReceived:[String:NSObject] = timer.userInfo as! [String:NSObject]
            let sessionUUID:String = dataReceived["SessionID"] as! String
            if(self.mcPeerIDToNode.keys.contains(sessionUUID)) {
                let failedPeerNode:FMNode = self.mcPeerIDToNode[sessionUUID]![dataReceived["FailedPeerID"] as! MCPeerID]!

                // make sure this thing is still in a failed state!
                if(self.nodeToResult[sessionUUID]!.keys.contains(failedPeerNode) == false) {
                    let work:FMWork = NSKeyedUnarchiver.unarchiveObject(with: dataReceived["FogToolWork"] as! Data) as! FMWork

                    self.FMLog(format: "Processing missing work for node " + failedPeerNode.description)

                    let peerResult:FMResult = self.fmTool.processWork(node: self.getSelfNode(), fromNode: self.getSelfNode(), work: work)

                    // store the result and merge results if needed
                    self.FMLog(format: "Storing re-processed result.")
                    self.nodeToResult[sessionUUID]![failedPeerNode] = peerResult
                    self.finishAndMerge(callerNode: self.getSelfNode(), sessionUUID: sessionUUID)
                } else {
                    self.FMLog(format: "No need to re-processed " + failedPeerNode.description + " work.  Work was returned.")
                }
            } else {
                self.FMLog(format: "No need to re-processed work, work came back and session completed.")
            }
        }

        timer.invalidate()
    }

    /**
     
     Log information to both NSLog and delegate it up to the FMTool
     
     - parameter format: The message you want to send/log
     
     */
    private func FMLog(format:String) {
        NSLog(format)
        fmTool.onLog(format: format)
    }
}
