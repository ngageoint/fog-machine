//
//  Transceiver.swift
//
//  Created by JP Simard on 11/3/14.
//  Copyright (c) 2014 JP Simard. All rights reserved.
//

import Foundation
import MultipeerConnectivity

/**
 
 Part of PeerPack used by FogMachine.  Developers using FogMachine will not need to use this.
 
 */
open class Transceiver: SessionDelegate {

    let advertiser: Advertiser
    let browser: Browser
    let displayName: String

    public init(displayName: String!) {
        self.displayName = displayName
        advertiser = Advertiser(displayName: displayName)
        browser = Browser(displayName: displayName)
        PeerPack.masterSession.delegate = self
    }

    open func startTransceiving(_ serviceType: String, discoveryInfo: [String: String]? = nil) {
        advertiser.startAdvertising(serviceType, discoveryInfo: discoveryInfo)
        browser.startBrowsing(serviceType)
    }

    func stopTransceiving() {
        advertiser.stopAdvertising()
        browser.stopBrowsing()
        PeerPack.masterSession.disconnect(displayName)
        NSLog("Disconnecting from transceiver.")
    }

    func startAdvertising(_ serviceType: String, discoveryInfo: [String: String]? = nil) {
        advertiser.startAdvertising(serviceType, discoveryInfo: discoveryInfo)
    }


    func startBrowsing(_ serviceType: String) {
        browser.startBrowsing(serviceType)
    }

    open func connecting(_ myPeerID: MCPeerID, toPeer peer: MCPeerID) {
        if let onConnecting = PeerPack.onConnecting {
            DispatchQueue.main.async {
                onConnecting(myPeerID, peer)
            }
        }
    }


    open func connected(_ myPeerID: MCPeerID, toPeer peer: MCPeerID) {
        if let onConnect = PeerPack.onConnect {
            DispatchQueue.main.async {
                onConnect(myPeerID, peer)
            }
        }
    }

    open func disconnected(_ myPeerID: MCPeerID, fromPeer peer: MCPeerID) {
        if let onDisconnect = PeerPack.onDisconnect {
            DispatchQueue.main.async {
                onDisconnect(myPeerID, peer)
            }

        }
    }

    open func receivedData(_ myPeerID: MCPeerID, data: Data, fromPeer peer: MCPeerID) {
        debugPrint("receivedData from \(peer.displayName) (on \(myPeerID.displayName))")
        if let dict = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String: AnyObject] {
            if let event = dict["event"] as? String {
                if let object: AnyObject = dict["object"] {
                    DispatchQueue.main.async {
                        if let onEvent = PeerPack.onEvent {
                            onEvent(peer, event, object)
                        }
                        if let eventBlock = PeerPack.eventBlocks[event] {
                            eventBlock(peer, object)
                        }
                    }
                }
            }
        }
    }

    open func finishReceivingResource(_ myPeerID: MCPeerID, resourceName: String, fromPeer peer: MCPeerID, atURL localURL: URL) {
        if let onFinishReceivingResource = PeerPack.onFinishReceivingResource {
            DispatchQueue.main.async {
                onFinishReceivingResource(myPeerID, resourceName, peer, localURL)
            }
        }
    }
}
