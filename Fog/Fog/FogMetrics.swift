//
//  FogMetrics.swift
//  Fog
//
//  Created by Chris Wasko on 3/24/16.
//  Copyright © 2016 NGA. All rights reserved.
//

import Foundation


public class FogMetrics {
    
    // Used for storing the Metrics
    var storedMetrics: Metrics<String, Metrics<String, Timer>> // [Device Name: Metrics<Metric Name, Time>]
    var devices: String
    
    init() {
        self.storedMetrics = Metrics<String, Metrics<String, Timer>>()
        self.devices = "Device(s): \n"
    }
    
    
    public func initialize() {
        self.storedMetrics = Metrics<String, Metrics<String, Timer>>()
        self.devices = "Device(s): \n"
    }
    
    
    func updateValue(value: Metrics<String, Timer>, forKey key: String) {
        guard let deviceMetrics = storedMetrics.getValue(key) else {
            storedMetrics.updateValue(value, forKey: key)
            return
        }
        
        for (event, timer) in value.getMetrics() {
            deviceMetrics.updateValue(timer, forKey: event)
        }
        
        storedMetrics.updateValue(deviceMetrics, forKey: key)
    }
    
    
    func removeValueForKey(key: String) {
        storedMetrics.removeValueForKey(key)
    }
    
    
    func startForMetric(metric: String) {
        guard let deviceMetrics = storedMetrics.getValue(Worker.getMe().displayName) else {
            //add new
            let newMetric = Metrics<String, Timer>()
            let timer = Timer()
            timer.startTimer()
            newMetric.updateValue(timer, forKey: metric)
            storedMetrics.updateValue(newMetric, forKey: Worker.getMe().displayName)
            return
        }
        
        let timer = Timer()
        timer.startTimer()
        deviceMetrics.updateValue(timer, forKey: metric)
        storedMetrics.updateValue(deviceMetrics, forKey: Worker.getMe().displayName)
    }
    
    
    func stopForMetric(metric: String) {
        guard let deviceMetrics = storedMetrics.getValue(Worker.getMe().displayName) else {
            return
        }
        
        if let timer = deviceMetrics.getValue(metric) {
            timer.stopTimer()
            deviceMetrics.updateValue(timer, forKey: metric)
            storedMetrics.updateValue(deviceMetrics, forKey: Worker.getMe().displayName)
        }
    }
    
    
    func mergeValueWithExisting(newMetrics: Metrics<String, Timer>) {
        guard let deviceMetrics = storedMetrics.getValue(Worker.getMe().displayName) else {
            self.updateValue(newMetrics, forKey: Worker.getMe().displayName)
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
        
        self.updateValue(newMergedValues, forKey: Worker.getMe().displayName)
    }
    
    
    func getValueForMetric(device: String, metric: String) -> Timer? {
        guard let deviceMetrics = storedMetrics.getValue(device) else {
            return nil
        }
        return deviceMetrics.getValue(metric)
    }
    
    
    public func getMetricsForDevice(device: String) -> Metrics<String, Timer>? {
        guard let deviceMetrics = storedMetrics.getValue(device) else {
            return nil
        }
        return deviceMetrics
    }
    
}