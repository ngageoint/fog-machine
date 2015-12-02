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
        PeerKit.transceive("fogmachine")
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
        
        receiving(responseEvent, sender: sender, receiver: receiver)
        
        responseMethod()
        
        if allReceived(responseEvent, sender: receiver) {
            completeMethod()
        }
    
    }
    
    
    static func sendEventTo(event: Event, object: [String: MPCSerializable]? = nil, sendTo: String) {
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
                PeerKit.sendEvent(event.rawValue, object: anyObject, toPeers: toPeer)
                //This is here as a reminder that there is a sleep here and to hopefully figure out a way to remove it.
                NSLog("I NEEDZ NAP")
                let alignment = "\t\t\t\t\t\t\t\t\t\t"
               print("\(alignment)           /\\_/\\ ")
               print("\(alignment)      ____/ o o \\ ")
               print("\(alignment)    /~____  =ø= /  ")
               print("\(alignment)   (______)__m_m)  ")
                // I dislike sleep's but this is required so the Multipeer Connectivity doesn't send events too fast to the same peer. (The events will go *poof* and never get sent if the sleep doesn't throttle them.)
                sleep(4)
                break
            }
        }

    }
    
    
    static func sendEventToAll<T: Work>(event: Event, workForPeer: (Int) -> (T), workForSelf: (Int) -> ()) {
        
        for peer in peers {
            hasReceivedResponse[Worker.getMe().displayName] = [event.rawValue:[peer.displayName: false]]
            let theWork = workForPeer(allWorkers.count)
            self.sendEventTo(event, object: [event.rawValue: theWork], sendTo: peer.displayName)
        }
        
        workForSelf(allWorkers.count)
        
    }
    
    
    static func sendEventForEach(event: Event, objectBlock: () -> ([String: MPCSerializable])) {
        for peer in ConnectionManager.peers {
            ConnectionManager.sendEvent(event, object: objectBlock(), toPeers: [peer])
        }
    }
    
}
