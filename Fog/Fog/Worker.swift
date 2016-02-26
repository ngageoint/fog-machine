//
//  Worker.swift
//  FogMachine
//
//  Created by Tyler Burgett on 8/10/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import PeerKit

private let myName = PeerKit.myName

public struct Worker: Hashable, Equatable, MPCSerializable {
    // MARK: Properties
    let name: String
    
    // MARK: Computed Properties
    var me: Bool { return name == myName }
    public var displayName: String { return name }
    public var hashValue: Int { return name.hash }
    public var mpcSerialized: NSData { return name.dataUsingEncoding(NSUTF8StringEncoding)! }
    
    // MARK: Initializers
    public init(name: String) {
        self.name = name
    }
    
    public init(mpcSerialized: NSData) {
        name = NSString(data: mpcSerialized, encoding: NSUTF8StringEncoding)! as String
    }
    
    public init(peer: MCPeerID) {
        name = peer.displayName
    }
    
    
    // MARK: Functions
    
    
    public static func getMe() -> Worker {
        return Worker(name: myName)
    }

}


public func ==(lhs: Worker, rhs: Worker) -> Bool {
    return lhs.name == rhs.name
}

