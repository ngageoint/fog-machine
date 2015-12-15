//
//  Advertiser.swift
//  CardsAgainst
//
//  Created by JP Simard on 11/3/14.
//  Copyright (c) 2014 JP Simard. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class Advertiser: NSObject, MCNearbyServiceAdvertiserDelegate {

    let theSession: Session
    let displayName: String
    private var advertiser: MCNearbyServiceAdvertiser?
    
    init(displayName: String, session: Session) {
        self.displayName = displayName
        self.theSession = session
        super.init()
    }
    

    func startAdvertising(serviceType serviceType: String, discoveryInfo: [String: String]? = nil) {
        advertiser = MCNearbyServiceAdvertiser(peer: theSession.getPeerId(displayName), discoveryInfo: discoveryInfo, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
    }
    

    func stopAdvertising() {
        advertiser?.delegate = nil
        advertiser?.stopAdvertisingPeer()
    }

    
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: NSData?, invitationHandler: ((Bool, MCSession) -> Void)) {
        guard let peerRunningTime = NSKeyedUnarchiver.unarchiveObjectWithData(context!) as! NSTimeInterval? else {
            return
        }

        let runningTime = -timeStarted.timeIntervalSinceNow
        let isPeerYounger = (peerRunningTime <= runningTime)
        print("isPeerYounger: \(isPeerYounger)  peerRunningTime: \(peerRunningTime) and runningTime: \(runningTime)")
        
        //let session = availableSession()
        
        if let aSession = theSession.getSession(displayName) {
            invitationHandler(isPeerYounger, aSession)
        }
        if isPeerYounger {
            advertiser.stopAdvertisingPeer()
            print("Advertiser \(advertiser.myPeerID.displayName) accepting \(peerID.displayName)")
        } else {
            print("Advertiser \(advertiser.myPeerID.displayName) NOT accepting \(peerID.displayName)")
        }
    }
    
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: NSError) {
        print("didNotStartAdvertisingPeer: \(error.localizedDescription)")
    }
    
    
}
