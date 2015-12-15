//
//  Session.swift
//  CardsAgainst
//
//  Created by JP Simard on 11/3/14.
//  Copyright (c) 2014 JP Simard. All rights reserved.
//

import Foundation
import MultipeerConnectivity


public protocol SessionDelegate {
    func connecting(myPeerID: MCPeerID, toPeer peer: MCPeerID)
    func connected(myPeerID: MCPeerID, toPeer peer: MCPeerID)
    func disconnected(myPeerID: MCPeerID, fromPeer peer: MCPeerID)
    func receivedData(myPeerID: MCPeerID, data: NSData, fromPeer peer: MCPeerID)
    func finishReceivingResource(myPeerID: MCPeerID, resourceName: String, fromPeer peer: MCPeerID, atURL localURL: NSURL)
}


public class Session: NSObject, MCSessionDelegate {
    
    //var newSession: MCSession
    var delegate: SessionDelegate?
    var myPeerSessions = [String: MCSession]()
    
    
    public init(displayName: String, delegate: SessionDelegate? = nil) {
        self.delegate = delegate
        let newSession = MCSession(peer: MCPeerID(displayName: displayName))
        super.init()
        newSession.delegate = self
        myPeerSessions[displayName] = newSession
    }

    
    public func disconnect(displayName: String) {
        //self.delegate = nil
        //mcSession.delegate = nil
        //mcSession.disconnect()
        
        //myPeerSessions[displayName]?.delegate = nil
        //myPeerSessions[displayName]?.disconnect()
        
        NSLog("Disconnecting \(displayName)")
    }
    
    
    func getSession(displayName: String) -> MCSession? {
        guard myPeerSessions.indexForKey(displayName) != nil else {
            return nil
        }
        return myPeerSessions[displayName]!
        //return newSession
    }
    
    
    public func getPeerId(displayName: String) -> MCPeerID {
        var peer: MCPeerID = MCPeerID(displayName: displayName)
        for (name, session) in myPeerSessions {
            if name == displayName {
                peer = session.myPeerID
            }
        }
            
        return peer
        //return newSession.myPeerID
    }
    

    // Some functions below adopted from:
    // http://stackoverflow.com/questions/23014523/multipeer-connectivity-framework-lost-peer-stays-in-session/23017463#23017463

    public func allConnectedPeers() -> [MCPeerID] {
        var allPeers: [MCPeerID] = []
        for (_, session) in myPeerSessions {
            for peer in session.connectedPeers {
                allPeers.append(peer)
            }
//            if session.myPeerID.displayName != myName {
//                allPeers.append(session.myPeerID)
//            }
        }
        return allPeers
        //return newSession.connectedPeers
    }
    
    
    public func allConnectedSessions() -> [MCSession] {
        var allSessions: [MCSession] = []
        for (_, session) in myPeerSessions {
            allSessions.append(session)
        }
        return allSessions
        //return [newSession]
    }
    
    
    
//    
//    
//    func availableSession() -> MCSession {
//        
//        //Try and use an existing session (_sessions is a mutable array)
//        for session: MCSession in mcSessions {
//            if session.connectedPeers.count < kMCSessionMaximumNumberOfPeers {
//                return session
//            }
//        }
//        
//        //Or create a new session
//        let newSession: MCSession = self.newSession()
//        mcSessions.append(newSession)
//        return newSession
//    }
//    
//    
//    func newSession() -> MCSession {
//        
//        let session: MCSession = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.Required)
//        session.delegate = self
//        return session
//        
//    }
//    
//    
    
    
    func sendData(data: NSData, toPeers peerIDs: [MCPeerID], withMode: MCSessionSendDataMode) {
        if peerIDs.count == 0 {
            return
        }
        
        // var peerNamePred: NSPredicate = NSPredicate(format: "displayName in %@", peerIDs["displayName"])
        //var mode: MCSessionSendDataMode = (reliable) ? MCSessionSendDataReliable : MCSessionSendDataUnreliable
        
        
        //Need to match up peers to their session
        for session: MCSession in allConnectedSessions() {
            do {
                try session.sendData(data, toPeers: peerIDs, withMode: withMode)
            } catch let errors as NSError{
                NSLog("Error sending data: \(errors.localizedDescription)")
            }
        }
    }
    
    
    // MARK: MCSessionDelegate

    
    public func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        let ids = "to peer \(peerID.displayName) from \(session.myPeerID.displayName)"
        switch state {
            case .Connecting:
                print("Connecting \(ids)")
                delegate?.connecting(session.myPeerID, toPeer: peerID)
            case .Connected:
                print("Connected \(ids)")
                //myPeerSessions[peerID.displayName] = session
                delegate?.connected(session.myPeerID, toPeer: peerID)
            case .NotConnected:
                print("NotConnected \(ids)")
                session.disconnect()
                //myPeerSessions.removeValueForKey(peerID.displayName)
                delegate?.disconnected(session.myPeerID, fromPeer: peerID)
        }
    }

    
    public func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        self.delegate?.receivedData(session.myPeerID, data: data, fromPeer: peerID)
    }

    
    public func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // unused
    }
    

    public func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {
        // unused
    }
    

    public func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
        // unused
        if error != nil {
            print("Error didFinishReceivingResourceWithName: \(error)")
        }
        if (error == nil) {
            delegate?.finishReceivingResource(session.myPeerID, resourceName: resourceName, fromPeer: peerID, atURL: localURL)
        }
    }
    
    
    public func session(session: MCSession, didReceiveCertificate certificate: [AnyObject]?, fromPeer peerID: MCPeerID, certificateHandler: (Bool) -> Void) {
        certificateHandler(true)
    }
    
}
