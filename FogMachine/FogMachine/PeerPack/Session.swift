//
//  Session.swift
//
//  Created by JP Simard on 11/3/14.
//  Copyright (c) 2014 JP Simard. All rights reserved.
//

import Foundation
import MultipeerConnectivity

/**
 
 Part of PeerPack used by FogMachine.  Developers using FogMachine will not need to use this.
 
 */
public protocol SessionDelegate {
    func connecting(myPeerID: MCPeerID, toPeer peer: MCPeerID)
    func connected(myPeerID: MCPeerID, toPeer peer: MCPeerID)
    func disconnected(myPeerID: MCPeerID, fromPeer peer: MCPeerID)
    func receivedData(myPeerID: MCPeerID, data: Data, fromPeer peer: MCPeerID)
    func finishReceivingResource(myPeerID: MCPeerID, resourceName: String, fromPeer peer: MCPeerID, atURL localURL: URL)
}

/**
 
 Part of PeerPack.  Developers using FogMachine will not need to use this.
 
 */
public class Session: NSObject, MCSessionDelegate {
    var delegate: SessionDelegate?
    var myPeerSessions = [String: MCSession]()
    public let myPeerId = MCPeerID(displayName: PeerPack.myName)

    public init(displayName: String, delegate: SessionDelegate? = nil) {
        self.delegate = delegate
        super.init()
        myPeerSessions[String(myPeerSessions.count)] = self.availableSession(displayName: displayName, peerName: displayName)
    }

    public func disconnect(displayName: String) {
        //self.delegate = nil
        //mcSession.delegate = nil
        //mcSession.disconnect()

        //myPeerSessions[displayName]?.delegate = nil
        //myPeerSessions[displayName]?.disconnect()

        if let session = self.getSession(displayName: displayName) {
            session.delegate = nil
            session.disconnect()
            myPeerSessions.removeValue(forKey: displayName)
        }
    }

    func getSession(displayName: String) -> MCSession? {
        guard myPeerSessions.index(forKey: displayName) != nil else {
            return nil
        }

        return myPeerSessions[displayName]!
    }

    func getPeerId() -> MCPeerID {
        return myPeerId
    }

    // Some functions below adopted from:
    // http://stackoverflow.com/questions/23014523/multipeer-connectivity-framework-lost-peer-stays-in-session/23017463#23017463

    public func allConnectedPeers() -> [MCPeerID] {
        var allPeers: [MCPeerID] = []
        for (_, session) in myPeerSessions {
            for peer in session.connectedPeers {
                allPeers.append(peer)
             }
        }
        return allPeers
    }

    public func allConnectedSessions() -> [MCSession] {
        var allSessions: [MCSession] = []

        for (_, session) in myPeerSessions {
            allSessions.append(session)
        }

        return allSessions
    }

    func availableSession(displayName: String, peerName: String) -> MCSession {
        var notFound = true
        var availableSession: MCSession? = nil

        //Try and use an existing session (_sessions is a mutable array)
        for (_, session) in myPeerSessions {
            if (session.connectedPeers.count < kMCSessionMaximumNumberOfPeers) {
                notFound = false
                availableSession = session
                break
            }
        }

        if notFound {
            availableSession = self.newSession(displayName: displayName, peerName: peerName)
        }

        return availableSession!
    }

    func newSession(displayName: String, peerName: String) -> MCSession {
        let newSession = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.required)

        newSession.delegate = self
        myPeerSessions[String(myPeerSessions.count)] = newSession

        return newSession
    }

    func sendData(data: Data, toPeers peerIDs: [MCPeerID], withMode: MCSessionSendDataMode) {
        guard peerIDs.count != 0  else {
            return
        }

        // Match up peers to their session
        for session: MCSession in allConnectedSessions() {
            do {
                try session.send(data, toPeers: peerIDs, with: withMode)
            } catch let errors as NSError{
                NSLog("Session error in sendData: \(errors.localizedDescription)")
            }
        }
    }

    // MARK: MCSessionDelegate

    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connecting:
            delegate?.connecting(myPeerID: session.myPeerID, toPeer: peerID)
        case .connected:
            //myPeerSessions[session.myPeerID.displayName] = session
            delegate?.connected(myPeerID: session.myPeerID, toPeer: peerID)
        case .notConnected:
            //self.disconnect(peerID.displayName)
            delegate?.disconnected(myPeerID: session.myPeerID, fromPeer: peerID)
        default:
            NSLog("Unexpected case")
        }
    }

    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        self.delegate?.receivedData(myPeerID: session.myPeerID, data: data, fromPeer: peerID)
    }

    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // unused
    }
    
    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // unsued
    }

    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // unused
        if error != nil {
            debugPrint("Error didFinishReceivingResourceWithName: \(error)")
        }
        if (error == nil) {
            delegate?.finishReceivingResource(myPeerID: session.myPeerID, resourceName: resourceName, fromPeer: peerID, atURL: localURL!)
        }
    }

    public func session(session: MCSession, didReceiveCertificate certificate: [AnyObject]?, fromPeer peerID: MCPeerID, certificateHandler: (Bool) -> Void) {
        certificateHandler(true)
    }
}
