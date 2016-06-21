//
//  Browser.swift
//
//  Created by JP Simard on 11/3/14.
//  Copyright (c) 2014 JP Simard. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class Browser: NSObject, MCNearbyServiceBrowserDelegate {
    let displayName: String
    var mcBrowser: MCNearbyServiceBrowser?

    init(displayName: String) {
        self.displayName = displayName
        super.init()
    }

    func startBrowsing(serviceType: String) {
        mcBrowser = MCNearbyServiceBrowser(peer: PeerPack.masterSession.getPeerId(), serviceType: serviceType)
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

        debugPrint("\tBrowser \(browser.myPeerID.displayName) found peerID \(peerID.displayName)")

        //Only invite from one side. Example: For devices A and B, only one should invite the other.
        let hasInvite = (displayName.componentsSeparatedByString(PeerPack.ID_DELIMITER)[1] > peerID.displayName.componentsSeparatedByString(PeerPack.ID_DELIMITER)[1])

        if (hasInvite) {
            debugPrint("\tBrowser sending invitePeer")
            let aSession = PeerPack.masterSession.availableSession(displayName, peerName: peerID.displayName)
            browser.invitePeer(peerID, toSession: aSession, withContext: nil, timeout: 30.0)
        }
        else {
            debugPrint("\tBrowser NOT sending invitePeer")

        }
    }

    func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        guard displayName != peerID.displayName else {
            return
        }

        debugPrint("\tBrowser \(browser.myPeerID.displayName) lost peer \(peerID.displayName)")
    }

    func browser(browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError) {
        debugPrint("\tBrowser didNotStartBrowsingForPeers: \(error.localizedDescription)")
    }
}
