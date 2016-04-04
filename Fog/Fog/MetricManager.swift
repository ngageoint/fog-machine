import Foundation


public class MetricManager {
    

    public var storedMetrics: Metrics<String, Metrics<String, Timer>> // [Device Name: Metrics<Metric Name, Time>]
    public var overall: Timer
    public var devices: String

    
    public init() {
        self.storedMetrics = Metrics<String, Metrics<String, Timer>>()
        self.overall = Timer()
        self.devices = "Device(s): \n"
    }
    
    
    public func initialize() {
        self.storedMetrics = Metrics<String, Metrics<String, Timer>>()
        self.overall = Timer()
        self.devices = "Device(s): \n"
    }
    
    
    public func addMetrics(newMetrics: Metrics<String, Metrics<String, Timer>>) {
        for (key, value) in newMetrics.getMetrics() {
            updateValue(value, forKey: key)
        }
    }
    
    
    public func updateValue(value: Metrics<String, Timer>, forKey key: String) {
        guard let deviceMetrics = storedMetrics.getValue(key) else {
            storedMetrics.updateValue(value, forKey: key)
            return
        }
        
        for (event, timer) in value.getMetrics() {
            deviceMetrics.updateValue(timer, forKey: event)
        }
        
        storedMetrics.updateValue(deviceMetrics, forKey: key)
    }
    
    
    public func removeValueForKey(key: String) {
        storedMetrics.removeValueForKey(key)
    }
    
    
    public func startOverall() {
        overall.startTimer()
    }
    
    
    public func stopOverall() {
        overall.stopTimer()
    }
    
    
    public func startForMetric(metric: String, deviceName: String = ConnectionManager.selfNode().displayName) {
        guard let deviceMetrics = storedMetrics.getValue(deviceName) else {
            //add new
            let newMetric = Metrics<String, Timer>()
            let timer = Timer()
            timer.startTimer()
            newMetric.updateValue(timer, forKey: metric)
            storedMetrics.updateValue(newMetric, forKey: deviceName)
            return
        }
        
        let timer = Timer()
        timer.startTimer()
        deviceMetrics.updateValue(timer, forKey: metric)
        storedMetrics.updateValue(deviceMetrics, forKey: deviceName)
    }
    
    
    public func stopForMetric(metric: String, deviceName: String = ConnectionManager.selfNode().displayName) {
        guard let deviceMetrics = storedMetrics.getValue(deviceName) else {
            return
        }
        
        if let timer = deviceMetrics.getValue(metric) {
            timer.stopTimer()
            deviceMetrics.updateValue(timer, forKey: metric)
            storedMetrics.updateValue(deviceMetrics, forKey: deviceName)
        }
    }
    
    
    public func getMetricsForDevice(device: String) -> Metrics<String, Timer>? {
        guard let deviceMetrics = storedMetrics.getValue(device) else {
            return nil
        }
        return deviceMetrics
    }
    
    
    public func getMetrics() -> Metrics<String, Metrics<String, Timer>> {
        return storedMetrics
    }
    
    
    public func mergeValueWithExisting(newMetrics: Metrics<String, Timer>, deviceName: String) {
        guard let deviceMetrics = storedMetrics.getValue(deviceName) else {
            self.updateValue(newMetrics, forKey: deviceName)
            return
        }
        
        let newMergedValues = Metrics<String, Timer>()
        
        for (key, value) in deviceMetrics.getMetrics() {
            for (newKey, newValue) in newMetrics.getMetrics() {
                if key == newKey {
                    let mergedTimer = Timer()
                    if value.getStart() == -1 {
                        mergedTimer.setStart(newValue.getStart())
                    } else {
                        mergedTimer.setStart(value.getStart())
                    }
                    if value.getEnd() == -1 {
                        mergedTimer.setEnd(newValue.getEnd())
                    } else {
                        mergedTimer.setEnd(value.getEnd())
                    }
                    mergedTimer.calculateElapsed()
                    newMergedValues.updateValue(mergedTimer, forKey: key)
                }
            }
        }
        
        self.updateValue(newMergedValues, forKey: deviceName)
    }
    
}