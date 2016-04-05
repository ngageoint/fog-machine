import Foundation


public class PeerAssurance {
    
    internal struct ReceivedData {
        var isReceived: Bool
        var timeoutSeconds: Double
        var startTime: CFAbsoluteTime
    }
    
    var deviceNode: Node
    var receivedData: ReceivedData
    var work: Work
    
    public init(deviceNode: Node, work: Work, timeoutSeconds: Double) {
        self.deviceNode = deviceNode
        self.work = work
        self.receivedData = ReceivedData(isReceived: false, timeoutSeconds: timeoutSeconds, startTime: CFAbsoluteTimeGetCurrent())
    }
    
    public func updateforReceipt() {
        receivedData.isReceived = true
    }
    
}
