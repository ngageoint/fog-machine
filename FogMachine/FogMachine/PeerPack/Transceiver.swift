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
public class Transceiver: SessionDelegate {

    let advertiser: Advertiser
    let browser: Browser
    let displayName: String

    public init(displayName: String!) {
        self.displayName = displayName
        advertiser = Advertiser(displayName: displayName)
        browser = Browser(displayName: displayName)
        PeerPack.masterSession.delegate = self
    }

    public func startTransceiving(serviceType serviceType: String, discoveryInfo: [String: String]? = nil) {
        advertiser.startAdvertising(serviceType: serviceType, discoveryInfo: discoveryInfo)
        browser.startBrowsing(serviceType)
    }

    func stopTransceiving() {
        advertiser.stopAdvertising()
        browser.stopBrowsing()
        PeerPack.masterSession.disconnect(displayName)
        NSLog("Disconnecting from transceiver.")
    }

    func startAdvertising(serviceType serviceType: String, discoveryInfo: [String: String]? = nil) {
        advertiser.startAdvertising(serviceType: serviceType, discoveryInfo: discoveryInfo)
    }


    func startBrowsing(serviceType serviceType: String) {
        browser.startBrowsing(serviceType)
    }

    public func connecting(myPeerID: MCPeerID, toPeer peer: MCPeerID) {
        if let onConnecting = PeerPack.onConnecting {
            dispatch_async(dispatch_get_main_queue()) {
                onConnecting(myPeerID: myPeerID, peerID: peer)
            }
        }
    }


    public func connected(myPeerID: MCPeerID, toPeer peer: MCPeerID) {
        if let onConnect = PeerPack.onConnect {
            dispatch_async(dispatch_get_main_queue()) {
                onConnect(myPeerID: myPeerID, peerID: peer)
            }
        }
    }

    public func disconnected(myPeerID: MCPeerID, fromPeer peer: MCPeerID) {
        if let onDisconnect = PeerPack.onDisconnect {
            dispatch_async(dispatch_get_main_queue()) {
                onDisconnect(myPeerID: myPeerID, peerID: peer)
            }

        }
    }

    public func receivedData(myPeerID: MCPeerID, data: NSData, fromPeer peer: MCPeerID) {
        debugPrint("receivedData from \(peer.displayName) (on \(myPeerID.displayName))")
        if let dict = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [String: AnyObject] {
            if let event = dict["event"] as? String {
                if let object: AnyObject? = dict["object"] {
                    dispatch_async(dispatch_get_main_queue()) {
                        if let onEvent = PeerPack.onEvent {
                            onEvent(peerID: peer, event: event, object: object)
                        }
                        if let eventBlock = PeerPack.eventBlocks[event] {
                            eventBlock(peerID: peer, object: object)
                        }
                    }
                }
            }
        }
    }

    public func finishReceivingResource(myPeerID: MCPeerID, resourceName: String, fromPeer peer: MCPeerID, atURL localURL: NSURL) {
        if let onFinishReceivingResource = PeerPack.onFinishReceivingResource {
            dispatch_async(dispatch_get_main_queue()) {
                onFinishReceivingResource(myPeerID: myPeerID, resourceName: resourceName, peer: peer, localURL: localURL)
            }
        }
    }
}
