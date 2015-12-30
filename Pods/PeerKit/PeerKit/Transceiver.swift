//
//  Transceiver.swift
//  CardsAgainst
//
//  Created by JP Simard on 11/3/14.
//  Copyright (c) 2014 JP Simard. All rights reserved.
//

import Foundation
import MultipeerConnectivity

enum TransceiverMode {
    case Browse, Advertise, Both
}

public class Transceiver: SessionDelegate {

    var transceiverMode = TransceiverMode.Both
    let session: Session
    let advertiser: Advertiser
    let browser: Browser

    
    public init(displayName: String!) {
        session = Session(displayName: displayName, delegate: nil)
        advertiser = Advertiser(displayName: displayName, session: session)
        browser = Browser(displayName: displayName, session: session)
        session.delegate = self
    }
    
    
    public func getSession() -> Session {
        return session
    }
    

    public func startTransceiving(serviceType serviceType: String, discoveryInfo: [String: String]? = nil) {
        advertiser.startAdvertising(serviceType: serviceType, discoveryInfo: discoveryInfo)
        browser.startBrowsing(serviceType)
        transceiverMode = .Both
    }
    

    func stopTransceiving() {
        session.delegate = nil
        advertiser.stopAdvertising()
        browser.stopBrowsing()
        
        //Need to handle this correctly
        //session.disconnect(session.myPeerID.displayName)
        NSLog("Disconnecting from transceiver.")
    }

    
    func startAdvertising(serviceType serviceType: String, discoveryInfo: [String: String]? = nil) {
        advertiser.startAdvertising(serviceType: serviceType, discoveryInfo: discoveryInfo)
        transceiverMode = .Advertise
    }

    
    func startBrowsing(serviceType serviceType: String) {
        browser.startBrowsing(serviceType)
        transceiverMode = .Browse
    }
    

    public func connecting(myPeerID: MCPeerID, toPeer peer: MCPeerID) {
        if masterSession == nil {
            masterSession = transceiver.getSession()
        }
        if let onConnecting = onConnecting {
            //print("onConnecting was valid")
            dispatch_async(dispatch_get_main_queue()) {
                onConnecting(myPeerID: myPeerID, peerID: peer)
            }
        } else {
            //Seens to always be invalid
            //print("onConnecting was INVALID")
        }
    }

    
    public func connected(myPeerID: MCPeerID, toPeer peer: MCPeerID) {
        let mySession = session.getSession(myPeerID.displayName)
        let peerSession = session.getSession(peer.displayName)
        
        if mySession == nil {
            print("\t\t\tTransceiver mySession: nil")
        } else {
            print("\t\t\tTransceiver mySession: \(mySession?.myPeerID.displayName)")
        }
        
        if peerSession == nil {
            print("\t\t\tTransceiver peerSession: nil")
        } else {
            print("\t\t\tTransceiver peerSession: \(peerSession?.myPeerID.displayName)")
        }
        
        
        //if session == nil {
        //    session = transceiver.session.mcSession
        
        
        
        
            //add to dictionary
            //  _myPeerSessions[peerID.displayName] = session;
            
            //broadcast connections to add to list, add to those who dont have it, and do not add to self
            //there is optimization to check if the path to a peer is shorter than an existing one, but for now dont worry, just get a simple case working
        
        
        
        
        //}
        if let onConnect = onConnect {
            dispatch_async(dispatch_get_main_queue()) {
                onConnect(myPeerID: myPeerID, peerID: peer)
            }
        }
    }
    

    public func disconnected(myPeerID: MCPeerID, fromPeer peer: MCPeerID) {
        //didDisconnect(myPeerID, peer: peer)
        if let onDisconnect = onDisconnect {
            dispatch_async(dispatch_get_main_queue()) {
                onDisconnect(myPeerID: myPeerID, peerID: peer)
            }
            
            
            //remove from dictionary
            
            //  [session disconnect];
            //  [_myPeerSessions removeObjectForKey:peerID.displayName];
            
            //broadcast to remove, if peer does not have, then don't continue to propagate
            //also brodcast other connections which are only sent through this peer (if any exist)
            
            
            
        }
    }

    
    public func receivedData(myPeerID: MCPeerID, data: NSData, fromPeer peer: MCPeerID) {
        print("Receiving data from \(peer.displayName) (on \(myPeerID.displayName))")
        if let dict = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [String: AnyObject] {
            if        let event = dict["event"] as? String {
                if let object: AnyObject? = dict["object"] {
                    print("\tunarchived data from \(peer.displayName)")
                    dispatch_async(dispatch_get_main_queue()) {
                        if let onEvent = onEvent {
                            print("\tonEvent")
                            onEvent(peerID: peer, event: event, object: object)
                        }
                        if let eventBlock = eventBlocks[event] {
                            print("\teventBlock")
                            eventBlock(peerID: peer, object: object)
                        }
                    }
                }
            }
        }
        print("\tEnd of didReceiveData from \(peer.displayName)")
    }
    

    public func finishReceivingResource(myPeerID: MCPeerID, resourceName: String, fromPeer peer: MCPeerID, atURL localURL: NSURL) {
        if let onFinishReceivingResource = onFinishReceivingResource {
            dispatch_async(dispatch_get_main_queue()) {
                onFinishReceivingResource(myPeerID: myPeerID, resourceName: resourceName, peer: peer, localURL: localURL)
            }
        }
    }
}
