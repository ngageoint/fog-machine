import Foundation


public class MetricManager {
    

    public var storedMetrics: Metrics<Node, Metrics<String, Timer>> // [Device Node: Metrics<Metric Name, Time>]
    public var overall: Timer
    public var devices: String

    
    public init() {
        self.storedMetrics = Metrics<Node, Metrics<String, Timer>>()
        self.overall = Timer()
        self.devices = "Device(s): \n"
    }
    
    
    public func initialize() {
        self.storedMetrics = Metrics<Node, Metrics<String, Timer>>()
        self.overall = Timer()
        self.devices = "Device(s): \n"
    }
    
    
    public func addMetrics(newMetrics: Metrics<Node, Metrics<String, Timer>>) {
        for (key, value) in newMetrics.getMetrics() {
            updateValue(value, forKey: key)
        }
    }
    
    
    public func updateValue(value: Metrics<String, Timer>, forKey key: Node) {
        guard let deviceMetrics = storedMetrics.getValue(key) else {
            storedMetrics.updateValue(value, forKey: key)
            return
        }
        
        for (event, timer) in value.getMetrics() {
            deviceMetrics.updateValue(timer, forKey: event)
        }
        
        storedMetrics.updateValue(deviceMetrics, forKey: key)
    }
    
    
    public func removeValueForKey(key: Node) {
        storedMetrics.removeValueForKey(key)
    }
    
    
    public func startOverall() {
        overall.start()
    }
    
    
    public func stopOverall() {
        overall.stop()
    }
    
    
    public func startForMetric(metric: String, deviceNode: Node) {
        guard let deviceMetrics = storedMetrics.getValue(deviceNode) else {
            //add new
            let newMetric = Metrics<String, Timer>()
            let timer = Timer()
            timer.start()
            newMetric.updateValue(timer, forKey: metric)
            storedMetrics.updateValue(newMetric, forKey: deviceNode)
            return
        }
        
        let timer = Timer()
        timer.start()
        deviceMetrics.updateValue(timer, forKey: metric)
        storedMetrics.updateValue(deviceMetrics, forKey: deviceNode)
    }
    
    
    public func stopForMetric(metric: String, deviceNode: Node) {
        guard let deviceMetrics = storedMetrics.getValue(deviceNode) else {
            return
        }
        
        if let timer = deviceMetrics.getValue(metric) {
            timer.stop()
            deviceMetrics.updateValue(timer, forKey: metric)
            storedMetrics.updateValue(deviceMetrics, forKey: deviceNode)
        }
    }
    
    
    public func getMetricsForDevice(deviceNode: Node) -> Metrics<String, Timer>? {
        guard let deviceMetrics = storedMetrics.getValue(deviceNode) else {
            return nil
        }
        return deviceMetrics
    }
    
    
    public func getMetrics() -> Metrics<Node, Metrics<String, Timer>> {
        return storedMetrics
    }
    
}