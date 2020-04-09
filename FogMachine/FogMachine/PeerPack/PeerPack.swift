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

    public typealias PeerBlock = ((_ myPeerID: MCPeerID, _ peerID: MCPeerID) -> Void)
    public typealias EventBlock = ((_ peerID: MCPeerID, _ event: String, _ object: AnyObject?) -> Void)
    public typealias ObjectBlock = ((_ peerID: MCPeerID, _ object: AnyObject?) -> Void)
    public typealias ResourceBlock = ((_ myPeerID: MCPeerID, _ resourceName: String, _ peer: MCPeerID, _ localURL: URL) -> Void)

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
        static let name = UIDevice.current.name
        static let id = UIDevice.current.identifierForVendor!.uuidString
        static public let myName = String(name + ID_DELIMITER + id)
    #else
        public let myName = NSHost.currentHost().localizedName ?? ""
    #endif

    static public var transceiver = Transceiver(displayName: myName)

    static public var masterSession: Session = Session(displayName: myName, delegate: nil)


    // MARK: Event Handling


    // MARK: Events


    static public func sendEvent(event: String, object: Any? = nil, toPeers peers: [MCPeerID]? = masterSession.allConnectedPeers()) {
        guard let peers = peers, !peers.isEmpty else {
            return
        }

        var rootObject: [String: Any] = ["event": event as Any]

        if let object: Any = object {
            rootObject["object"] = object
        }

        let data = NSKeyedArchiver.archivedData(withRootObject: rootObject)

        masterSession.sendData(data: data, toPeers: peers, withMode: .reliable)
    }
}
