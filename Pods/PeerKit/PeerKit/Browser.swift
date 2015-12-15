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

    let theSession: Session
    let displayName: String
    
    var mcBrowser: MCNearbyServiceBrowser?
    
    
    init(displayName: String, session: Session) {
        self.displayName = displayName
        self.theSession = session
        super.init()
    }


    func startBrowsing(serviceType: String) {
        mcBrowser = MCNearbyServiceBrowser(peer: theSession.getPeerId(displayName), serviceType: serviceType)
        mcBrowser?.delegate = self
        mcBrowser?.startBrowsingForPeers()
    }

    
    func stopBrowsing() {
        mcBrowser?.delegate = nil
        mcBrowser?.stopBrowsingForPeers()
    }

    
    func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        
        print("Browser \(browser.myPeerID.displayName) found peerID \(peerID.displayName)")
        let runningTime = -timeStarted.timeIntervalSinceNow
        //print("runningTime: \(runningTime)")

        let context = NSKeyedArchiver.archivedDataWithRootObject(runningTime)

        if let aSession = theSession.getSession(displayName) {
            print("sending invitePeer")
            browser.invitePeer(peerID, toSession: aSession, withContext: context, timeout: 30)
        }
    }
    

    func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Browser \(browser.myPeerID.displayName) lost peer \(peerID.displayName)")
    }
    
    
    func browser(browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError) {
        print("didNotStartBrowsingForPeers: \(error.localizedDescription)")
    }
}
