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
    var metrics: Metrics<String, Metrics<String, Timer>>
    var overall: Timer
    var devices: String
    
    // Used for processing the Metrics
    var totalManager = [String: CFAbsoluteTime]() // [Metric Name : Time]
    var individualManager = [String: Metrics<String, CFAbsoluteTime>]() // [Metric Name: Metrics<Device Name, Time>]
    // Update the outputOrder with the order the metrics total/individual times will be displayed
    let outputOrder = [Metric.VIEWSHED,
                       Metric.OVERLAY,
                       Metric.Data.READING,
                       Metric.Data.SENDING,
                       Metric.Data.MERGING]
 
    
    init() {
        self.metrics = Metrics<String, Metrics<String, Timer>>()
        self.overall = Timer()
        self.devices = "Device(s): \n"
    }
    
    
    func updateValue(value: Metrics<String, Timer>, forKey key: String) {
        metrics.updateValue(value, forKey: key)
    }
    
    
    func removeValueForKey(key: String) {
        metrics.removeValueForKey(key)
    }
    
    
    func startOverall() {
        overall.startTimer()
    }
    
    
    func stopOverall() {
        overall.stopTimer()
    }
    
    
    func initialize() {
        self.metrics = Metrics<String, Metrics<String, Timer>>()
        self.overall = Timer()
        self.devices = "Device(s): \n"
        self.totalManager.removeAll()
        self.individualManager.removeAll()
    }
    
    func processMetrics() {
        for (device, metric) in metrics.getMetrics() {
            devices += "\t\t\(device)\n"
            for (event, timer) in metric.getMetrics() {
                addToTotal(event, value: timer.getElapsed())
                addToIndividual(event, metricKey: device, metricValue: timer.getElapsed())
            }
        }
    }
    
    
    func addToTotal(key: String, value: CFAbsoluteTime) {
        
        guard let oldValue = totalManager[key] else {
            totalManager.updateValue(value, forKey: key)
            return
        }
        
        let newValue = value + oldValue
        totalManager.updateValue(newValue, forKey: key)
    }

    
    func addToIndividual(key: String, metricKey: String, metricValue: CFAbsoluteTime) {
        guard let updateValue = individualManager[key] else {
            let newValue = Metrics<String, CFAbsoluteTime>()
            newValue.updateValue(metricValue, forKey: metricKey)
            individualManager.updateValue(newValue, forKey: key)
            return
        }
        
        updateValue.updateValue(metricValue, forKey: metricKey)
        individualManager.updateValue(updateValue, forKey: key)
    }
    
    
    func getOutput() -> String {
        var output = "\n"
        output += devices
        output += getTotalTimeForKey(Metric.WORK)
        
        for key in outputOrder {
            output += getTotalTimeForKey(key)
            output += getIndividualTimesForKey(key)
        }

        output += getOverallTime()
        output += "\n"
        
        return output
    }
    
    
    // MARK: Private Functions
    
    
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
        
        var output = "\t\(key)\t\(formatTime(value)) seconds ("
        output += getPercentage(value, total: self.overall.getElapsed())
        output += " of Overall Time)\n"
        
        return output
    }

    
    private func getIndividualTimesForKey(key: String) -> String {
        guard let value = individualManager[key] else {
            return ""
        }
        guard let totalValue = totalManager[key] else {
            return ""
        }
        
        var output = ""

        for (device, time) in value.getMetrics() {
            output = "\t\t\(device): \(formatTime(time)) seconds  ("
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