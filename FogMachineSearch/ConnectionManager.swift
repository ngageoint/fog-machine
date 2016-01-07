//
//  ConnectionManager.swift
//  FogMachineSearch
//
//  Created by Tyler Burgett on 8/10/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

import Foundation
import PeerKit
import MultipeerConnectivity

protocol MPCSerializable {
    var mpcSerialized: NSData { get }
    init(mpcSerialized: NSData)
}


struct ConnectionManager {
    

    static var hasReceivedResponse:[String:[String:[String:Bool]]] = ["sender": ["event":["peer":true]]] //better way to do this?
    static private let serialQueue = dispatch_queue_create("mil.nga.magic.fog", DISPATCH_QUEUE_SERIAL)
    
    // MARK: Properties
    private static var peers: [MCPeerID] {
        return PeerKit.session?.connectedPeers ?? []
    }
    
    static var otherWorkers: [Worker] {
        return peers.map { Worker(peer: $0) }
    }
    
    static var allWorkers: [Worker] {
        return [Worker.getMe()] + otherWorkers
    }
    
    
    // MARK: Start
    static func start() {
        NSLog("Transceiving")
        PeerKit.transceive(Fog.SERVICE_TYPE)
    }
    
    
    // MAARK: Event handling
    static func onConnect(run: PeerBlock?) {
        NSLog("Connection made")
        PeerKit.onConnect = run
    }
    
    static func onDisconnect(run: PeerBlock) {
        PeerKit.onDisconnect = run
    }
    
    static func onEvent(event: Event, run: ObjectBlock?) {
        if let run = run {
            PeerKit.eventBlocks[event.rawValue] = run
        } else {
            PeerKit.eventBlocks.removeValueForKey(event.rawValue)
        }
    }
    
    
    // MARK: Receipt Assurance
    
    
    static func receiving(event: Event, sender: String, receiver: String) {
        guard let theReceiver = hasReceivedResponse[receiver] else {
            return
        }
        guard let theEvent = theReceiver[event.rawValue] else {
            return
        }
        guard (theEvent[sender] != nil) else {
            return
        }
        hasReceivedResponse[receiver]![event.rawValue]![sender] = true
        
    }

    
    static func allReceived(event: Event, sender: String) -> Bool {
        guard (hasReceivedResponse[sender] != nil) else {
            return false
        }
        
        var result = true
        
        for (_, value) in hasReceivedResponse[sender]![event.rawValue]! {
            if (value == false) {
                result = false
            }
        }
        
        return result
    }
    
    
    // MARK: Sending
    static func sendEvent(event: Event, object: [String: MPCSerializable]? = nil, toPeers peers: [MCPeerID]? = PeerKit.session?.connectedPeers ) {
        var anyObject: [String: NSData]?
        if let object = object {
            anyObject = [String: NSData]()
            for (key, value) in object {
                anyObject![key] = value.mpcSerialized
            }
        }
        PeerKit.sendEvent(event.rawValue, object: anyObject, toPeers: peers)
    }
    
    
    static func processResult(event: Event, responseEvent: Event, sender: String, receiver: String, object: [String: MPCSerializable], responseMethod: () -> (), completeMethod: () -> ()) {
        
        //dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
        dispatch_barrier_async(self.serialQueue) {
            responseMethod()
            
            receiving(responseEvent, sender: sender, receiver: receiver)
            
          //  dispatch_async(dispatch_get_main_queue()) {
                
                
                if allReceived(responseEvent, sender: receiver) {
                    completeMethod()
                }
         //   }
        }
    }
    
    
    static func sendEventTo(event: Event, willThrottle: Bool = false, object: [String: MPCSerializable]? = nil, sendTo: String) {
        var anyObject: [String: NSData]?
        if let object = object {
            anyObject = [String: NSData]()
            for (key, value) in object {
                anyObject![key] = value.mpcSerialized
            }
        }
        
        for peer in peers {
            if peer.displayName == sendTo {
                let toPeer:[MCPeerID] = [peer]
                if willThrottle {
                    //This is not currently needed, but keeping it here in case it's used for other testing/debugging
                    //self.throttle()
                }
                PeerKit.sendEvent(event.rawValue, object: anyObject, toPeers: toPeer)
                break
            }
        }

    }
    
    
    static func throttle() {
        // I dislike sleep's but this was being used so the Multipeer Connectivity doesn't send events too fast to the same peer. (The events will go *poof* and never get sent if the sleep doesn't throttle them.) Although this does not always work so it might be related to some other unknown issue.
        let sleepAmount:UInt32 = UInt32(peers.count * 5 + 1)
        //Output is here as a reminder that there is a sleep
        NSLog("I NEEDZ NAP FOR \(sleepAmount) SECONDZ")
        let alignment = "\t\t\t\t\t\t\t\t\t\t\t\t\t"
        print("\(alignment)           /\\_/\\ ")
        print("\(alignment)      ____/ o o \\ ")
        print("\(alignment)    /~____  =ø= /  ")
        print("\(alignment)   (______)__m_m)  ")
        sleep(UInt32(arc4random_uniform(sleepAmount) + sleepAmount))
    }
    
    
    static func sendEventToPeer<T: Work>(event: Event, willThrottle: Bool = false, workForPeer: (count: Int) -> (T), workForSelf: (Int) -> (), log: (String) -> (), selectedWorkersCount: Int, selectedPeers: Array<String>) { //, peerName: String) {
        
        workForSelf(selectedWorkersCount)
        print("selectedWorkersCount-> : \(selectedWorkersCount)")
        print("selectedPeers-> : \(selectedPeers)")
        // The barrier is used to sync sends to receipts and prevent a really fast device from finishing and sending results back before any other device has been sent their results, causing the response queue to only have one sent entry
        // The processResult function uses the same barrier so the first result is not processed until all the Work has been sent out
        dispatch_barrier_async(self.serialQueue) {
            for peerName in selectedPeers {
                //if peer.displayName == peerName {
                hasReceivedResponse[Worker.getMe().displayName] = [event.rawValue:[peerName: false]]
                let theWork = workForPeer(count: selectedWorkersCount)
                print("theWork : \(theWork)")
                self.sendEventTo(event, willThrottle: willThrottle, object: [event.rawValue: theWork], sendTo: peerName)
                log(peerName)
            }
        }
    }
    
    static func sendEventToAll<T: Work>(event: Event, willThrottle: Bool = false, workForPeer: (Int) -> (T), workForSelf: (Int) -> (), log: (String) -> ()) {
        
        workForSelf(allWorkers.count)
        
        // The barrier is used to sync sends to receipts and prevent a really fast device from finishing and sending results back before any other device has been sent their results, causing the response queue to only have one sent entry
        // The processResult function uses the same barrier so the first result is not processed until all the Work has been sent out
        dispatch_barrier_async(self.serialQueue) {
            for peer in peers {
                hasReceivedResponse[Worker.getMe().displayName] = [event.rawValue:[peer.displayName: false]]
                let theWork = workForPeer(allWorkers.count)
                self.sendEventTo(event, willThrottle: willThrottle, object: [event.rawValue: theWork], sendTo: peer.displayName)
                log(peer.displayName)
            }
        }
    }
    
    
    static func sendEventForEach(event: Event, objectBlock: () -> ([String: MPCSerializable])) {
        for peer in ConnectionManager.peers {
            ConnectionManager.sendEvent(event, object: objectBlock(), toPeers: [peer])
        }
    }
    
}
