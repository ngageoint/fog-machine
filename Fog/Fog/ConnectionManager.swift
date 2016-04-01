//
//  ConnectionManager.swift
//  FogMachine
//
//  Created by Tyler Burgett on 8/10/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

import Foundation
import PeerKit
import MultipeerConnectivity


public var fogMetrics = FogMetrics()

public class ConnectionManager {
    
    static private let serialQueue = dispatch_queue_create("mil.nga.giat.fogmachine", DISPATCH_QUEUE_SERIAL)
    static private var receiptAssurance = ReceiptAssurance(sender: ConnectionManager.selfPeerID().displayName)
    
    // MARK: Properties
    
    private static func selfPeerID() -> MCPeerID {
        return PeerKit.masterSession.myPeerId
    }
    
    public static func selfNode() -> Node {
        return Node(uniqueId: PeerKit.myName.componentsSeparatedByString(PeerKit.delimiter)[1], displayName: PeerKit.myName.componentsSeparatedByString(PeerKit.delimiter)[0])
    }

    private static func allPeerIDs() -> [MCPeerID] {
        return PeerKit.masterSession.allConnectedPeers() ?? []
    }
    
    public static func allPeerNodes() -> [Node] {
        var nodes: [Node] = []
        for peerId in ConnectionManager.allPeerIDs() {
            nodes.append(Node(uniqueId: peerId.displayName.componentsSeparatedByString(PeerKit.delimiter)[1], displayName: peerId.displayName.componentsSeparatedByString(PeerKit.delimiter)[0]))
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
    
    
    public static func onEvent(event: String, run: ObjectBlock?) {
        if let run = run {
            PeerKit.eventBlocks[event] = run
        } else {
            PeerKit.eventBlocks.removeValueForKey(event)
        }
    }
    
    
    // MARK: Sending
    
    
    public static func sendEvent(event: String, object: [String: MPCSerializable]? = nil, toPeers peers: [MCPeerID]? =
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
    
    
    public static func processResult(event: String, responseEvent: String, sender: String, object: [String: MPCSerializable], responseMethod: () -> (), completeMethod: () -> ()) {
        //dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
        dispatch_barrier_async(self.serialQueue) {
            fogMetrics.startForMetric(Fog.Metric.RECEIVE)
            responseMethod()
            printOut("processResult from \(sender)")
            receiptAssurance.updateForReceipt(responseEvent, receiver: sender)
            
          //  dispatch_async(dispatch_get_main_queue()) {

            if receiptAssurance.checkAllReceived(responseEvent) {
                printOut("Running completeMethod()")
                completeMethod()
                receiptAssurance.removeAllForEvent(responseEvent)
            } else if receiptAssurance.checkForTimeouts(responseEvent) {
                printOut("Timeout found")
                self.reprocessWork(responseEvent)
            } else {
                printOut("Not done and no timeouts yet.")
            }
            fogMetrics.stopForMetric(Fog.Metric.RECEIVE)
         //   }
        }
    }
    
    
    public static func sendEventTo(event: String, object: [String: MPCSerializable]? = nil, sendTo: String) {
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
    
    public static func sendEventToAll<T: Work>(event: String, timeoutSeconds: Double = 30.0, workForPeer: (Int) -> (T), workForSelf: (Int) -> (), log: (String) -> ()) {
        
        workForSelf(ConnectionManager.allNodes().count)
        
        // The barrier is used to sync sends to receipts and prevent a really fast device from finishing and sending results back before any other device has been sent their results, causing the response queue to only have one sent entry
        // The processResult function uses the same barrier so the first result is not processed until all the Work has been sent out
        dispatch_barrier_async(self.serialQueue) {
            fogMetrics.startForMetric(Fog.Metric.SEND)
            for peer in ConnectionManager.allPeerIDs() {
                let theWork = workForPeer(ConnectionManager.allNodes().count)
                
                receiptAssurance.add(peer.displayName, event: event, work: theWork, timeoutSeconds:  timeoutSeconds)
                
                self.sendEventTo(event, object: [event: theWork], sendTo: peer.displayName)
                log(peer.displayName)
            }
            fogMetrics.stopForMetric(Fog.Metric.SEND)
        }
        receiptAssurance.startTimer(event, timeoutSeconds: timeoutSeconds)
    }
    
    
    public static func checkForTimeouts(responseEvent: String) {
        printOut("timer in ConnectionManager")
        
        while receiptAssurance.checkForTimeouts(responseEvent) {
            printOut("detected timed out work")
            self.reprocessWork(responseEvent)
        }
    }
    
    
    public static func reprocessWork(responseEvent: String) {
        let peer = receiptAssurance.getFinishedPeer(responseEvent)
        
        if let finishedPeer = peer {
            printOut("found peer \(finishedPeer) to finish work")
            let work = receiptAssurance.getNextTimedOutWork(responseEvent)
            
            if let timedOutWork = work {
                printOut("found work to finish")
                self.sendEventTo(responseEvent, object: [responseEvent: timedOutWork], sendTo: finishedPeer)
            }
        }
    }
    
    
    public static func sendEventForEach(event: String, objectBlock: () -> ([String: MPCSerializable])) {
        for peer in ConnectionManager.allPeerIDs() {
            sendEvent(event, object: objectBlock(), toPeers: [peer])
        }
    }
 
    
    public static func printOut(output: String) {
        dispatch_async(dispatch_get_main_queue()) {
            //NSLog(output)
        }
    }
    
}
