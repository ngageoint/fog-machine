import Foundation
import PeerKit
import MultipeerConnectivity


public var fogMetrics = MetricManager()

public class ConnectionManager {
    
    public var fogTool: FogTool
    private let serialQueue = dispatch_queue_create("mil.nga.giat.fogmachine", DISPATCH_QUEUE_SERIAL)
    private var receiptAssurance = ReceiptAssurance(sender: ConnectionManager.selfNode())

    
    public init(fogTool: FogTool) {
        self.fogTool = fogTool
    }
    
    
    // MARK: Properties
    
    
    private static func selfPeerID() -> MCPeerID {
        return PeerKit.masterSession.myPeerId
    }
    
    public static func selfNode() -> Node {
        return Node(uniqueId: PeerKit.myName.componentsSeparatedByString(PeerKit.ID_DELIMITER)[1], displayName: PeerKit.myName.componentsSeparatedByString(PeerKit.ID_DELIMITER)[0])
    }
    
    
    private static func allPeerIDs() -> [MCPeerID] {
        return PeerKit.masterSession.allConnectedPeers() ?? []
    }
    
    public static func allPeerNodes() -> [Node] {
        var nodes: [Node] = []
        for peerId in ConnectionManager.allPeerIDs() {
            nodes.append(Node(uniqueId: peerId.displayName.componentsSeparatedByString(PeerKit.ID_DELIMITER)[1], displayName: peerId.displayName.componentsSeparatedByString(PeerKit.ID_DELIMITER)[0]))
        }
        nodes.sortInPlace { (obj1, obj2) -> Bool in
            return obj1.uniqueId < obj2.uniqueId
        }
        return nodes
    }
    
    

    public static func allNodes() -> [Node] {
        var nodes: [Node] = []
        nodes.append(ConnectionManager.selfNode())
        nodes += allPeerNodes()
        nodes.sortInPlace { (obj1, obj2) -> Bool in
            return obj1.uniqueId < obj2.uniqueId
        }
        return nodes
    }
    
    
    // MARK: Start
    
    
    public static func start() {
        NSLog("Transceiving")
        transceiver.startTransceiving(serviceType: Fog.SERVICE_TYPE)
    }
    
    
    // MARK: Event handling
    
    
    public static func onConnect(run: PeerBlock?) {
        NSLog("Connection made")
        PeerKit.onConnect = run
    }
    
    
    public static func onDisconnect(run: PeerBlock) {
        PeerKit.onDisconnect = run
    }
    
    
    public func onEvent(event: String, run: ObjectBlock?) {
        if let run = run {
            PeerKit.eventBlocks[event] = run
        } else {
            PeerKit.eventBlocks.removeValueForKey(event)
        }
    }
    
    
    // MARK: Sending
    
    
    public func sendEvent(event: String, object: [String: MPCSerializable]? = nil, toPeers peers: [MCPeerID]? =
        PeerKit.masterSession.allConnectedPeers()) {
        var anyObject: [String: NSData]?
        if let object = object {
            anyObject = [String: NSData]()
            for (key, value) in object {
                anyObject![key] = value.mpcSerialized
            }
        }
        PeerKit.sendEvent(event, object: anyObject, toPeers: peers)
    }
    
    
    public func processResult(event: String, responseEvent: String, sender: MCPeerID, object: [String: MPCSerializable]) {
        //dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
        let senderNode = Node(mcPeerId: sender)
        dispatch_barrier_async(self.serialQueue) {
            fogMetrics.startForMetric(Fog.Metric.RECEIVE, deviceNode: senderNode)
            self.fogTool.processResult(result: object, fromPeerId: sender)
            self.printOut("processResult from \(sender)")
            self.receiptAssurance.updateForReceipt(responseEvent, receiver: senderNode)

            //  dispatch_async(dispatch_get_main_queue()) {
            fogMetrics.stopForMetric(Fog.Metric.RECEIVE, deviceNode: senderNode)
            if self.receiptAssurance.checkAllReceived(responseEvent) {
                self.printOut("Running completeMethod()")
                self.fogTool.completeWork()
                self.receiptAssurance.removeAllForEvent(responseEvent)
            } else if self.receiptAssurance.checkForTimeouts(responseEvent) {
                self.printOut("Timeout found")
                self.reprocessWork(responseEvent)
            } else {
                self.printOut("Not done and no timeouts yet.")
            }
        }
    }
    
    
    public func sendEventTo(event: String, object: [String: MPCSerializable]? = nil, sendTo: String) {
        var anyObject: [String: NSData]?
        if let object = object {
            anyObject = [String: NSData]()
            for (key, value) in object {
                anyObject![key] = value.mpcSerialized
            }
        }
        
        for peer in ConnectionManager.allPeerIDs() {
            if peer.displayName == sendTo {
                let toPeer:[MCPeerID] = [peer]
                
                PeerKit.sendEvent(event, object: anyObject, toPeers: toPeer)
                break
            }
        }
        
    }
    
    
    public func sendEventToAll(event: String, timeoutSeconds: Double = 30.0, metadata: AnyObject)
    {
        var hasPeers = false
        var deviceCounter = 1
        let selfWork = self.fogTool.workDivider(currentQuadrant: deviceCounter, numberOfQuadrants: ConnectionManager.allNodes().count, metadata: metadata)
        self.receiptAssurance.add(ConnectionManager.selfNode(), event: event, work: selfWork, timeoutSeconds: timeoutSeconds)
        
        // The barrier is used to sync sends to receipts and prevent a really fast device from finishing and sending results back before any other device has been sent their results, causing the response queue to only have one sent entry
        // The processResult function uses the same barrier so the first result is not processed until all the Work has been sent out
        dispatch_barrier_async(self.serialQueue) {
            for peer in ConnectionManager.allPeerIDs() {
                hasPeers = true
                deviceCounter = deviceCounter + 1
                let peerNode = Node(mcPeerId: peer)
                fogMetrics.startForMetric(Fog.Metric.SEND, deviceNode: peerNode)
                let theWork = self.fogTool.workDivider(currentQuadrant: deviceCounter, numberOfQuadrants: ConnectionManager.allNodes().count, metadata: metadata)
                theWork.workerNode = Node(mcPeerId: peer)
                
                self.receiptAssurance.add(peerNode, event: event, work: theWork, timeoutSeconds:  timeoutSeconds)
                
                self.sendEventTo(event, object: [event: theWork], sendTo: peer.displayName)
                self.fogTool.log(peerName: peer.displayName)
                fogMetrics.stopForMetric(Fog.Metric.SEND, deviceNode: peerNode)
            }
        }
        receiptAssurance.startTimer(event, timeoutSeconds: timeoutSeconds, reprocessMethod: ConnectionManager.reprocessWork(self))
        dispatch_barrier_async(self.serialQueue) {

        self.fogTool.selfWork(selfWork: selfWork, hasPeers: hasPeers)
        self.receiptAssurance.updateForReceipt(event, receiver: ConnectionManager.selfNode())
        }
    }
    
    
    public func checkForTimeouts(responseEvent: String) {
        printOut("timer in ConnectionManager")
        
        while receiptAssurance.checkForTimeouts(responseEvent) {
            printOut("detected timed out work")
            self.reprocessWork(responseEvent)
        }
    }
    
    
    public func reprocessWork(responseEvent: String) {
        let peer = receiptAssurance.getFinishedPeer(responseEvent)
        let work = receiptAssurance.getNextTimedOutWork(responseEvent)
        if let timedOutWork = work {
            self.printOut("Found work to finish")
            if !peer.isSelf() {
                self.printOut("Found peer \(peer.displayName) to finish work")
                self.sendEventTo(responseEvent, object: [responseEvent: timedOutWork], sendTo: (peer.displayName + PeerKit.ID_DELIMITER + peer.uniqueId))
            } else if peer.isSelf() {
                self.fogTool.selfWork(selfWork: timedOutWork, hasPeers: true)
                // Handle situation when all peers are done and only the initiator is processing work.
                //   Once done, the initiator needs to call complete.
                if receiptAssurance.checkAllReceived(responseEvent) {
                    printOut("Running completeMethod()")
                    self.fogTool.completeWork()
                    receiptAssurance.removeAllForEvent(responseEvent)
                }
            }
        }
    }
    
    
    public func sendEventForEach(event: String, objectBlock: () -> ([String: MPCSerializable])) {
        for peer in ConnectionManager.allPeerIDs() {
            sendEvent(event, object: objectBlock(), toPeers: [peer])
        }
    }
    
    //Used for debugging
    private func printOut(output: String) {
        dispatch_async(dispatch_get_main_queue()) {
            //NSLog(output)
        }
    }
    
}
