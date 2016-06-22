//
//  PeerPack.swift
//
//  Created by JP Simard on 11/5/14.
//  Copyright (c) 2014 JP Simard. All rights reserved.
//

import Foundation
import MultipeerConnectivity

#if os(iOS)
    import UIKit
#endif

/**
 
 PeerPack used by FogMachine.  Developers using FogMachine will not need to use this.
 
 */
public class PeerPack {

    // MARK: Type Aliases

    public typealias PeerBlock = ((myPeerID: MCPeerID, peerID: MCPeerID) -> Void)
    public typealias EventBlock = ((peerID: MCPeerID, event: String, object: AnyObject?) -> Void)
    public typealias ObjectBlock = ((peerID: MCPeerID, object: AnyObject?) -> Void)
    public typealias ResourceBlock = ((myPeerID: MCPeerID, resourceName: String, peer: MCPeerID, localURL: NSURL) -> Void)

    // MARK: Event Blocks

    static public var onConnecting: PeerBlock?
    static public var onConnect: PeerBlock?
    static public var onDisconnect: PeerBlock?
    static public var onEvent: EventBlock?
    static public var onEventObject: ObjectBlock?
    static public var onFinishReceivingResource: ResourceBlock?
    static public var eventBlocks = [String: ObjectBlock]()


    // MARK: PeerPack Globals

    static public let ID_DELIMITER: String = "\t"

    #if os(iOS)
        // Use the device name, along with the UUID for the device separated by a tab character
        static let name = UIDevice.currentDevice().name
        static let id = UIDevice.currentDevice().identifierForVendor!.UUIDString
        static public let myName = String(name + ID_DELIMITER + id)
    #else
        public let myName = NSHost.currentHost().localizedName ?? ""
    #endif

    static public var transceiver = Transceiver(displayName: myName)

    static public var masterSession: Session = Session(displayName: myName, delegate: nil)


    // MARK: Event Handling


    // MARK: Events


    static public func sendEvent(event: String, object: AnyObject? = nil, toPeers peers: [MCPeerID]? = masterSession.allConnectedPeers()) {
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
}
