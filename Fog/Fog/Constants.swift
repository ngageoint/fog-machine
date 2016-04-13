import Foundation


public struct Fog {
    // Service type can contain only ASCII lowercase letters, numbers, and hyphens. 
    // It must be a unique string, at most 15 characters long
    // Note: Devices will only connect to other devices with the same serviceType value.
    static let SERVICE_TYPE = "fog-machine"
    public static let WORKER_NODE = "WorkerNode"
    public static let METRICS = "FogMetrics"
    
    
    public struct Metric {
        public static let SEND = "Fog Send Work"
        public static let RECEIVE = "Fog Handle Result"
        
        // Update with the order the metrics will be displayed
        static let OUTPUT_ORDER = [Fog.Metric.SEND,
                                   Fog.Metric.RECEIVE]
    }
}


struct Time {
    static let START = "start"
    static let END = "end"
    static let ELAPSED = "elapsed"
}

enum FogMachineError: ErrorType {
    case PeerIDError
}