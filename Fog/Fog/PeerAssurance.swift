//
//  PeerAssurance.swift
//  FogMachine
//
//  Created by Chris Wasko on 2/10/16.
//  Copyright © 2016 NGA. All rights reserved.
//

import Foundation


public class PeerAssurance {
    
    internal struct ReceivedData {
        var isReceived: Bool
        var timeoutSeconds: Double
        var startTime: CFAbsoluteTime
    }
    
    var name: String!
    var receivedData: ReceivedData!
    var work: Work!
    
    public init(name: String, work: Work, timeoutSeconds: Double) {
        self.name = name
        self.work = work
        self.receivedData = ReceivedData(isReceived: false, timeoutSeconds: timeoutSeconds, startTime: CFAbsoluteTimeGetCurrent())
    }
    
    public func updateforReceipt() {
        receivedData.isReceived = true
    }
    
}
