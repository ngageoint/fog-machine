//
//  ReceiptAssurance.swift
//  FogMachine
//
//  Created by Chris Wasko on 2/10/16.
//  Copyright © 2016 NGA. All rights reserved.
//

import Foundation

class ReceiptAssurance: NSObject {
    

    var sender: String
    var assurance: [String:[PeerAssurance]] //Event: PeerAssurance

    
    init(sender: String) {
        self.sender = sender
        self.assurance = [:]
    }
    
    
    // MARK: Receipt Assurance
    
    
    func add(peer: String, event: Event, work: Work, timeoutSeconds: Double) {
        printOut("Adding: peer: \(peer), event: \(event.rawValue)")
        let newPeerAssurance = PeerAssurance(name: peer, work: work, timeoutSeconds: timeoutSeconds)
        
        if assurance[event.rawValue] == nil {
            assurance[event.rawValue] = [newPeerAssurance]
        } else {
            assurance[event.rawValue]?.append(newPeerAssurance)
        }
    }
    
    
    func removeAllForEvent(event: Event) {
        assurance.removeValueForKey(event.rawValue)
    }
    
    
    func updateForReceipt(event: Event, receiver: String) {
        printOut("updateForReceipt")
        guard assurance[event.rawValue] != nil else {
            printOut("guard hit")
            return
        }
        
        for peer in assurance[event.rawValue]! {
            //printOut("\tpeer \(peer.name)")
            if peer.name == receiver {
                //printOut("\tpeer \(peer.name) marking true")
                peer.updateforReceipt()
            }
        }
    }
    
    
    func checkAllReceived(event: Event) -> Bool {
        printOut("Checking for all received")
        guard assurance[event.rawValue] != nil else {
            printOut("guard hit")
            return false
        }
        var result = true
        
        for peer in assurance[event.rawValue]! {
            //printOut("\tpeer \(peer.name) has value \(peer.receivedData.isReceived)")
            if !peer.receivedData.isReceived {
                result = false
                break
            }
        }
        
        return result
    }
    
    
    func checkForTimeouts(event: Event) -> Bool {
        printOut("Checking for timeouts")
        guard assurance[event.rawValue] != nil else {
            printOut("guard hit")
            return false
        }
        var result = false
        
        for peer in assurance[event.rawValue]! {
            let runTime = CFAbsoluteTimeGetCurrent() - peer.receivedData.startTime
            //printOut("\tpeer \(peer.name) has value \(runTime)")
            if runTime > peer.receivedData.timeoutSeconds && !peer.receivedData.isReceived {
                result = true
                break
            }
        }
        
        return result
    }
    
    
    func getNextTimedOutWork(event: Event) -> Work? {
        printOut("getNextTimedOutWork")
        guard assurance[event.rawValue] != nil else {
            printOut("guard hit")
            return nil
        }
        var work: Work? = nil
        
        for peer in assurance[event.rawValue]! {
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
    
    
    func getFinishedPeer(event: Event) -> String? {
        printOut("getFinishedPeer")
        guard assurance[event.rawValue] != nil else {
            printOut("guard hit")
            return nil
        }
        var peerName: String? = nil
        
        for peer in assurance[event.rawValue]! {
            //printOut("\tpeer \(peer.name) has value \(peer.receivedData.isReceived)")
            if peer.receivedData.isReceived {
                peerName = peer.name
                break
            }
        }
        
        return peerName
    }
    
    
    func startTimer(event: Event, timeoutSeconds: Double) {
        //printOut("Starting Timer for \(timeoutSeconds) seconds")
        dispatch_async(dispatch_get_main_queue()) {
            NSTimer.scheduledTimerWithTimeInterval(timeoutSeconds, target: self, selector: Selector("timerAction:"), userInfo: event.rawValue, repeats: false)
        }
        
    }
    
    
    func timerAction(timer: NSTimer) {
        //printOut("TimeoutAction")
        let event = Event(rawValue: timer.userInfo as! String)!
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
