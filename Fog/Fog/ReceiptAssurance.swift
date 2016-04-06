import Foundation


public class ReceiptAssurance: NSObject {
    

    var sender: Node
    var assurance: [String:[PeerAssurance]] //Event: PeerAssurance
    var reprocessMethod: ((String) -> ())? = nil
    
    public init(sender: Node) {
        self.sender = sender
        self.assurance = [:]
    }
    
    
    // MARK: Receipt Assurance
    
    
    public func add(peer: Node, event: String, work: Work, timeoutSeconds: Double) {
        printOut("Adding: peer: \(peer.displayName), event: \(event)")
        let newPeerAssurance = PeerAssurance(deviceNode: peer, work: work, timeoutSeconds: timeoutSeconds)
        
        if assurance[event] == nil {
            assurance[event] = [newPeerAssurance]
        } else {
            assurance[event]?.append(newPeerAssurance)
        }
    }
    
    
    public func removeAllForEvent(event: String) {
        assurance.removeValueForKey(event)
    }
    
    
    public func updateForReceipt(event: String, receiver: Node) {
        printOut("updateForReceipt")
        guard assurance[event] != nil else {
            printOut("guard hit")
            return
        }
        
        for peer in assurance[event]! {
            //printOut("\tpeer \(peer.name)")
            if peer.deviceNode == receiver {
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
    
    
    public func getFinishedPeer(event: String) -> Node {
        printOut("getFinishedPeer")
        guard assurance[event] != nil else {
            return ConnectionManager.selfNode()
        }
        var peerNode: Node = ConnectionManager.selfNode()
        
        for peer in assurance[event]! {
            //printOut("\tpeer \(peer.name) has value \(peer.receivedData.isReceived)")
            if !peer.deviceNode.isSelf() {
                if peer.receivedData.isReceived {
                    peerNode = peer.deviceNode
                    break
                }
            }
        }
        
        return peerNode
    }
    
    
    public func startTimer(event: String, timeoutSeconds: Double, reprocessMethod: (String) -> ()) {
        //printOut("Starting Timer for \(timeoutSeconds) seconds")
        self.reprocessMethod = reprocessMethod
        dispatch_async(dispatch_get_main_queue()) {
            NSTimer.scheduledTimerWithTimeInterval(timeoutSeconds, target: self, selector: #selector(ReceiptAssurance.timerAction(_:)), userInfo: event, repeats: false)
        }
        
    }
    
    
    public func timerAction(timer: NSTimer) {
        //printOut("TimeoutAction")
        let event = timer.userInfo as! String
        while checkForTimeouts(event) {
            printOut("detected timed out work")
            self.reprocessMethod!(event)
        }
        dispatch_async(dispatch_get_main_queue()) {
            timer.invalidate()
        }
    }
    
    //Used for debugging
    private func printOut(output: String) {
        dispatch_async(dispatch_get_main_queue()) {
            //NSLog(output)
        }
    }
    
}
