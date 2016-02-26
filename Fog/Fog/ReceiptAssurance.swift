//
//  ReceiptAssurance.swift
//  FogMachine
//
//  Created by Chris Wasko on 2/10/16.
//  Copyright © 2016 NGA. All rights reserved.
//

import Foundation


public class ReceiptAssurance: NSObject {
    

    var sender: String
    var assurance: [String:[PeerAssurance]] //Event: PeerAssurance

    
    public init(sender: String) {
        self.sender = sender
        self.assurance = [:]
    }
    
    
    // MARK: Receipt Assurance
    
    
    public func add(peer: String, event: String, work: Work, timeoutSeconds: Double) {
        printOut("Adding: peer: \(peer), event: \(event)")
        let newPeerAssurance = PeerAssurance(name: peer, work: work, timeoutSeconds: timeoutSeconds)
        
        if assurance[event] == nil {
            assurance[event] = [newPeerAssurance]
        } else {
            assurance[event]?.append(newPeerAssurance)
        }
    }
    
    
    public func removeAllForEvent(event: String) {
        assurance.removeValueForKey(event)
    }
    
    
    public func updateForReceipt(event: String, receiver: String) {
        printOut("updateForReceipt")
        guard assurance[event] != nil else {
            printOut("guard hit")
            return
        }
        
        for peer in assurance[event]! {
            //printOut("\tpeer \(peer.name)")
            if peer.name == receiver {
                //printOut("\tpeer \(peer.name) marking true")
                peer.updateforReceipt()
            }
        }
    }
    
    
    public func checkAllReceived(event: String) -> Bool {
        printOut("Checking for all received")
        guard assurance[event] != nil else {
            printOut("guard hit")
            return false
        }
        var result = true
        
        for peer in assurance[event]! {
            //printOut("\tpeer \(peer.name) has value \(peer.receivedData.isReceived)")
            if !peer.receivedData.isReceived {
                result = false
                break
            }
        }
        
        return result
    }
    
    
    public func checkForTimeouts(event: String) -> Bool {
        printOut("Checking for timeouts")
        guard assurance[event] != nil else {
            printOut("guard hit")
            return false
        }
        var result = false
        
        for peer in assurance[event]! {
            let runTime = CFAbsoluteTimeGetCurrent() - peer.receivedData.startTime
            //printOut("\tpeer \(peer.name) has value \(runTime)")
            if runTime > peer.receivedData.timeoutSeconds && !peer.receivedData.isReceived {
                result = true
                break
            }
        }
        
        return result
    }
    
    
    public func getNextTimedOutWork(event: String) -> Work? {
        printOut("getNextTimedOutWork")
        guard assurance[event] != nil else {
            printOut("guard hit")
            return nil
        }
        var work: Work? = nil
        
        for peer in assurance[event]! {
            let runTime = CFAbsoluteTimeGetCurrent() - peer.receivedData.startTime
            //printOut("\tpeer \(peer.name) has value \(runTime)")
            if runTime > peer.receivedData.timeoutSeconds && !peer.receivedData.isReceived {
                // Update to acknowledge it being handled
                // Will need to consider a better approach than updating here
                peer.updateforReceipt()
                work = peer.work
                break
            }
        }

        return work
    }
    
    
    public func getFinishedPeer(event: String) -> String? {
        printOut("getFinishedPeer")
        guard assurance[event] != nil else {
            printOut("guard hit")
            return nil
        }
        var peerName: String? = nil
        
        for peer in assurance[event]! {
            //printOut("\tpeer \(peer.name) has value \(peer.receivedData.isReceived)")
            if peer.receivedData.isReceived {
                peerName = peer.name
                break
            }
        }
        
        return peerName
    }
    
    
    public func startTimer(event: String, timeoutSeconds: Double) {
        //printOut("Starting Timer for \(timeoutSeconds) seconds")
        dispatch_async(dispatch_get_main_queue()) {
            NSTimer.scheduledTimerWithTimeInterval(timeoutSeconds, target: self, selector: Selector("timerAction:"), userInfo: event, repeats: false)
        }
        
    }
    
    
    public func timerAction(timer: NSTimer) {
        //printOut("TimeoutAction")
        let event = timer.userInfo as! String
        ConnectionManager.checkForTimeouts(event)
        dispatch_async(dispatch_get_main_queue()) {
            timer.invalidate()
        }
    }
    
    
    func printOut(output: String) {
        dispatch_async(dispatch_get_main_queue()) {
            //NSLog(output)
        }
    }
    
}
