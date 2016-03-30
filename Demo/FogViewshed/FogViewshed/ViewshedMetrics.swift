//
//  ViewshedMetrics.swift
//  FogViewshed
//
//  Created by Chris Wasko on 3/22/16.
//  Copyright © 2016 NGA. All rights reserved.
//

import Foundation
import Fog

class ViewshedMetrics {
    
    // Used for storing the Metrics
    var storedMetrics: Metrics<String, Metrics<String, Timer>> // [Device Name: Metrics<Metric Name, Time>]
    var overall: Timer
    var devices: String
    
    // Used for processing the Metrics
    var totalManager = [String: CFAbsoluteTime]() // [Metric Name : Time]
    var individualManager = [String: Metrics<String, CFAbsoluteTime>]() // [Metric Name: Metrics<Device Name, Time>]

    
    init() {
        self.storedMetrics = Metrics<String, Metrics<String, Timer>>()
        self.overall = Timer()
        self.devices = "Device(s): \n"
    }
    
    
    func initialize() {
        self.storedMetrics = Metrics<String, Metrics<String, Timer>>()
        self.overall = Timer()
        self.devices = "Device(s): \n"
        self.totalManager.removeAll()
        self.individualManager.removeAll()
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
    
    
    func startOverall() {
        overall.startTimer()
    }
    
    
    func stopOverall() {
        overall.stopTimer()
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

    
    func processMetrics() {
        for (device, deviceMetrics) in storedMetrics.getMetrics() {
            devices += "\t\t\(device)\n"
            for (event, timer) in deviceMetrics.getMetrics() {
                addToTotal(event, value: timer.getElapsed())
                addToIndividual(event, metricKey: device, metricValue: timer.getElapsed())
            }
        }
    }

    
    func getOutput() -> String {
        var output = "\n"
        output += devices
        output += "\n"
        
        for key in Metric.OUTPUT_ORDER {
            var metricOutput = ""
            metricOutput += getTotalTimeForKey(key)
            metricOutput += getIndividualTimesForKey(key)
            if metricOutput != "" {
                output += metricOutput
                output += "\n"
            }
        }

        output += getOverallTime()
        output += "\n"

        return output
    }
    
    
    func getMetricsForDevice(device: String) -> Metrics<String, Timer>? {
        guard let deviceMetrics = storedMetrics.getValue(device) else {
            return nil
        }
        return deviceMetrics
    }
    
    
    // MARK: Private Functions

    
    private func addToTotal(key: String, value: CFAbsoluteTime) {
        guard let oldValue = totalManager[key] else {
            totalManager.updateValue(value, forKey: key)
            return
        }
        
        let newValue = value + oldValue
        totalManager.updateValue(newValue, forKey: key)
    }
    
    
    private func addToIndividual(key: String, metricKey: String, metricValue: CFAbsoluteTime) {
        guard let updateValue = individualManager[key] else {
            let newValue = Metrics<String, CFAbsoluteTime>()
            newValue.updateValue(metricValue, forKey: metricKey)
            individualManager.updateValue(newValue, forKey: key)
            return
        }
        
        updateValue.updateValue(metricValue, forKey: metricKey)
        individualManager.updateValue(updateValue, forKey: key)
    }
    
    
    private func getOverallTime() -> String {
        var output = "Total Overall Time: "
        output += formatTime(self.overall.getElapsed())
        output += " seconds"

        return output
    }
    
    
    private func getTotalTimeForKey(key: String) -> String {
        guard let value = totalManager[key] else {
            return ""
        }
        
        var output = "\t\(key):\n\t\t\t\(formatTime(value))s ("
        output += getPercentage(value, total: self.overall.getElapsed())
        output += " of Overall Time)\n"
        
        return output
    }

    
    private func getIndividualTimesForKey(key: String) -> String {
        guard let individualMetrics = individualManager[key] else {
            return ""
        }
        guard let totalValue = totalManager[key] else {
            return ""
        }
        
        var output = ""

        for (device, time) in individualMetrics.getMetrics() {
            output += "\t\t\(device):\n\t\t\t\(formatTime(time))s ("
            output += self.getPercentage(time, total: totalValue)
            output += " of \(key))\n"
        }

        return output
    }
    
    
    private func getPercentage(value: CFAbsoluteTime, total: CFAbsoluteTime) -> String {
        let percentage: Double = (value / total) * 100.0

        return "\(String(format: "%.1f", percentage))%"
    }
    
    
    private func formatTime(time: CFAbsoluteTime) -> String {
        return String(format: "%.3f", time)
    }
    
}