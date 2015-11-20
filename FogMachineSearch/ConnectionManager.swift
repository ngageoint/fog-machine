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
        PeerKit.transceive("fogsearch")
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
    
    
    static func sendEventForEach(event: Event, objectBlock: () -> ([String: MPCSerializable])) {
        for peer in ConnectionManager.peers {
            ConnectionManager.sendEvent(event, object: objectBlock(), toPeers: [peer])
        }
    }
}
