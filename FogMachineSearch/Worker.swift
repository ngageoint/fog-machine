//
//  Worker.swift
//  FogMachineSearch
//
//  Created by Tyler Burgett on 8/10/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

import Foundation
import MultipeerConnectivity

private let myName = UIDevice.currentDevice().name

struct Worker: Hashable, Equatable, MPCSerializable {
    // MARK: Properties
    let name: String
    
    // MARK: Computed Properties
    var me: Bool { return name == myName }
    var displayName: String { return me ? "You" : name }
    var hashValue: Int { return name.hash }
    var mpcSerialized: NSData { return name.dataUsingEncoding(NSUTF8StringEncoding)! }
    
    // MARK: Initializers
    init(name: String) {
        self.name = name
    }
    
    init(mpcSerialized: NSData) {
        name = NSString(data: mpcSerialized, encoding: NSUTF8StringEncoding)! as String
    }
    
    init(peer: MCPeerID) {
        name = peer.displayName
    }
    
    static func getMe() -> Worker {
        return Worker(name: myName)
    }
    
    // MARK: Methods
}


func ==(lhs: Worker, rhs: Worker) -> Bool {
    return lhs.name == rhs.name
}

