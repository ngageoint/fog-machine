//
//  Advertiser.swift
//
//  Created by JP Simard on 11/3/14.
//  Copyright (c) 2014 JP Simard. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class Advertiser: NSObject, MCNearbyServiceAdvertiserDelegate {
    let displayName: String
    private var advertiser: MCNearbyServiceAdvertiser?

    init(displayName: String) {
        self.displayName = displayName
        super.init()
    }

    func startAdvertising(serviceType serviceType: String, discoveryInfo: [String: String]? = nil) {
        advertiser = MCNearbyServiceAdvertiser(peer: PeerPack.masterSession.getPeerId(), discoveryInfo: discoveryInfo, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
    }

    func stopAdvertising() {
        advertiser?.delegate = nil
        advertiser?.stopAdvertisingPeer()
    }

    func advertiser(advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: NSData?, invitationHandler: ((Bool, MCSession) -> Void)) {
        guard displayName != peerID.displayName else {
            return
        }

        let aSession = PeerPack.masterSession.availableSession(displayName, peerName: peerID.displayName)
        invitationHandler(true, aSession)

        advertiser.stopAdvertisingPeer()

        debugPrint("Advertiser \(advertiser.myPeerID.displayName) accepting \(peerID.displayName)")
    }

    func advertiser(advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: NSError) {
        debugPrint("Advertiser didNotStartAdvertisingPeer: \(error.localizedDescription)")
    }
}
