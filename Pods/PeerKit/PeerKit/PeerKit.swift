//
//  PeerKit.swift
//  CardsAgainst
//
//  Created by JP Simard on 11/5/14.
//  Copyright (c) 2014 JP Simard. All rights reserved.
//

import Foundation
import MultipeerConnectivity


// MARK: Type Aliases


public typealias PeerBlock = ((myPeerID: MCPeerID, peerID: MCPeerID) -> Void)
public typealias EventBlock = ((peerID: MCPeerID, event: String, object: AnyObject?) -> Void)
public typealias ObjectBlock = ((peerID: MCPeerID, object: AnyObject?) -> Void)
public typealias ResourceBlock = ((myPeerID: MCPeerID, resourceName: String, peer: MCPeerID, localURL: NSURL) -> Void)


// MARK: Event Blocks


public var onConnecting: PeerBlock?
public var onConnect: PeerBlock?
public var onDisconnect: PeerBlock?
public var onEvent: EventBlock?
public var onEventObject: ObjectBlock?
public var onFinishReceivingResource: ResourceBlock?
public var eventBlocks = [String: ObjectBlock]()


// MARK: PeerKit Globals


#if os(iOS)
    import UIKit
    //Added 😺 and hash() as a unique identifier to allow multiple iPhone simulators to run PeerKit simultaneously
    public let myName = String(UIDevice.currentDevice().name + "😺" + String(UIDevice.currentDevice().hash))
#else
    public let myName = NSHost.currentHost().localizedName ?? ""
#endif

public var transceiver = Transceiver(displayName: myName)

public var masterSession: Session = Session(displayName: myName, delegate: nil)


// MARK: Event Handling


// MARK: Events


public func sendEvent(event: String, object: AnyObject? = nil, toPeers peers: [MCPeerID]? = masterSession.allConnectedPeers()) {
    guard let peers = peers where !peers.isEmpty else {
        return
    }
    
    var rootObject: [String: AnyObject] = ["event": event]
    
    if let object: AnyObject = object {
        rootObject["object"] = object
    }
    
    let data = NSKeyedArchiver.archivedDataWithRootObject(rootObject)
    
    masterSession.sendData(data, toPeers: peers, withMode: .Reliable)
}


// MARK: Development


public let debug = false

public func print(message: String) {
    if debug {
        print(message)
    }
}