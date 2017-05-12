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
open class PeerPack {

    // MARK: Type Aliases

    public typealias PeerBlock = ((_ myPeerID: MCPeerID, _ peerID: MCPeerID) -> Void)
    public typealias EventBlock = ((_ peerID: MCPeerID, _ event: String, _ object: AnyObject?) -> Void)
    public typealias ObjectBlock = ((_ peerID: MCPeerID, _ object: AnyObject?) -> Void)
    public typealias ResourceBlock = ((_ myPeerID: MCPeerID, _ resourceName: String, _ peer: MCPeerID, _ localURL: URL) -> Void)

    // MARK: Event Blocks

    static open var onConnecting: PeerBlock?
    static open var onConnect: PeerBlock?
    static open var onDisconnect: PeerBlock?
    static open var onEvent: EventBlock?
    static open var onEventObject: ObjectBlock?
    static open var onFinishReceivingResource: ResourceBlock?
    static open var eventBlocks = [String: ObjectBlock]()


    // MARK: PeerPack Globals

    static open let ID_DELIMITER: String = "\t"

    #if os(iOS)
        // Use the device name, along with the UUID for the device separated by a tab character
        static let name = UIDevice.current.name
        static let id = UIDevice.current.identifierForVendor!.uuidString
        static open let myName = String(name + ID_DELIMITER + id)
    #else
        public let myName = NSHost.currentHost().localizedName ?? ""
    #endif

    static open var transceiver = Transceiver(displayName: myName)

    static open var masterSession: Session = Session(displayName: myName!, delegate: nil)


    // MARK: Event Handling


    // MARK: Events


    static open func sendEvent(_ event: String, object: AnyObject? = nil, toPeers peers: [MCPeerID]? = masterSession.allConnectedPeers()) {
        guard let peers = peers, !peers.isEmpty else {
            return
        }

        var rootObject: [String: AnyObject] = ["event": event as AnyObject]

        if let object: AnyObject = object {
            rootObject["object"] = object
        }

        let data = NSKeyedArchiver.archivedData(withRootObject: rootObject)

        masterSession.sendData(data, toPeers: peers, withMode: .reliable)
    }
}
