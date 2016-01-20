//
//  Browser.swift
//  CardsAgainst
//
//  Created by JP Simard on 11/3/14.
//  Copyright (c) 2014 JP Simard. All rights reserved.
//

import Foundation
import MultipeerConnectivity

let timeStarted = NSDate()

class Browser: NSObject, MCNearbyServiceBrowserDelegate {

    let displayName: String
    
    var mcBrowser: MCNearbyServiceBrowser?
    
    
    init(displayName: String) {
        self.displayName = displayName
        super.init()
    }


    func startBrowsing(serviceType: String) {
        mcBrowser = MCNearbyServiceBrowser(peer: masterSession.getPeerId(), serviceType: serviceType)
        mcBrowser?.delegate = self
        mcBrowser?.startBrowsingForPeers()
    }

    
    func stopBrowsing() {
        mcBrowser?.delegate = nil
        mcBrowser?.stopBrowsingForPeers()
    }

    
    func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        guard displayName != peerID.displayName else {
            return
        }

        print("\tBrowser \(browser.myPeerID.displayName) found peerID \(peerID.displayName)")
        
        //Only invite from one side. Example: For devices A and B, only one should invite the other.
        let hasInvite = (displayName.componentsSeparatedByString("😺")[1] > peerID.displayName.componentsSeparatedByString("😺")[1])
        
        if (hasInvite) {
            print("\tBrowser sending invitePeer using session")
            let aSession = masterSession.availableSession(displayName, peerName: peerID.displayName)
            browser.invitePeer(peerID, toSession: aSession, withContext: nil, timeout: 30.0)
        }
        else {
            print("\tBrowser NOT sending invitePeer")

        }
    }
    

    func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        guard displayName != peerID.displayName else {
            return
        }

        //Remove from myPeerSessions? Or only on NotConnected remove from myPeersession?
        //Also, if this is called from one phone, does the other phone still connect? 
        //Example: (phone A and B); A does not connect to B, so A lostPeer B, but B connects to
        // A so Session is connected from B to A. (Meaning it makes no difference which phone connected
        //  to which, only that one connected and the other didn't).
        
        print("\tBrowser \(browser.myPeerID.displayName) lost peer \(peerID.displayName)")
    }
    
    
    func browser(browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError) {
        print("\tBrowser didNotStartBrowsingForPeers: \(error.localizedDescription)")
    }
}
