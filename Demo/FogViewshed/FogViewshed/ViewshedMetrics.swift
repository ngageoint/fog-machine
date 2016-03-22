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
    
    var metrics: Metrics<String, Metrics<String, Timer>>
    var overall: Timer
    var devices: String
    var totalTimeReadingData: CFAbsoluteTime
    var totalTimeViewshed: CFAbsoluteTime
    var totalTimeOverlay: CFAbsoluteTime
    var totalTimeSendingData: CFAbsoluteTime
    var totalTimeMergingData: CFAbsoluteTime
    var totalTimeWork: CFAbsoluteTime
    var individualTimeReadingData: Metrics<String, CFAbsoluteTime>
    var individualTimeViewshed: Metrics<String, CFAbsoluteTime>
    var individualTimeOverlay: Metrics<String, CFAbsoluteTime>
    var individualTimeSendingData: Metrics<String, CFAbsoluteTime>
    var individualTimeMergingData: Metrics<String, CFAbsoluteTime>
    
    
    init() {
        self.metrics = Metrics<String, Metrics<String, Timer>>()
        self.overall = Timer()
        self.devices = "Device(s): \n"
        self.totalTimeReadingData = 0
        self.totalTimeViewshed = 0
        self.totalTimeOverlay = 0
        self.totalTimeSendingData = 0
        self.totalTimeMergingData = 0
        self.totalTimeWork = 0
        self.individualTimeMergingData = Metrics<String, CFAbsoluteTime>()
        self.individualTimeSendingData = Metrics<String, CFAbsoluteTime>()
        self.individualTimeReadingData = Metrics<String, CFAbsoluteTime>()
        self.individualTimeViewshed = Metrics<String, CFAbsoluteTime>()
        self.individualTimeOverlay = Metrics<String, CFAbsoluteTime>()
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
        self.totalTimeReadingData = 0
        self.totalTimeViewshed = 0
        self.totalTimeOverlay = 0
        self.totalTimeSendingData = 0
        self.totalTimeMergingData = 0
        self.totalTimeWork = 0
        self.individualTimeMergingData = Metrics<String, CFAbsoluteTime>()
        self.individualTimeSendingData = Metrics<String, CFAbsoluteTime>()
        self.individualTimeReadingData = Metrics<String, CFAbsoluteTime>()
        self.individualTimeViewshed = Metrics<String, CFAbsoluteTime>()
        self.individualTimeOverlay = Metrics<String, CFAbsoluteTime>()
    }
    
    func processMetrics() {
        for (device, metric) in metrics.getMetrics() {
            devices += "\t\t\(device)\n"
            for (event, timer) in metric.getMetrics() {
                addToTotalTime(event, value: timer.getElapsed())
                addToIndividualTime(event, value: timer.getElapsed(), name: device)
            }
        }
    }
    
    
    func addToTotalTime(key: String, value: CFAbsoluteTime) {
        if key == Metric.VIEWSHED {
            totalTimeViewshed += value
        } else if key == Metric.OVERLAY {
            totalTimeOverlay += value
        } else if key == Metric.WORK {
            totalTimeWork += value
        } else if key == Metric.Data.READING {
            totalTimeReadingData += value
        } else if key == Metric.Data.SENDING {
            totalTimeSendingData += value
        } else if key == Metric.Data.MERGING {
            totalTimeMergingData += value
        }
    }

    
    func addToIndividualTime(key: String, value: CFAbsoluteTime, name: String) {
        if key == Metric.VIEWSHED {
            individualTimeViewshed.updateValue(value, forKey: name)
        } else if key == Metric.OVERLAY {
            individualTimeOverlay.updateValue(value, forKey: name)
        } else if key == Metric.Data.READING {
            individualTimeReadingData.updateValue(value, forKey: name)
        } else if key == Metric.Data.SENDING {
            individualTimeSendingData.updateValue(value, forKey: name)
        } else if key == Metric.Data.MERGING {
            individualTimeMergingData.updateValue(value, forKey: name)
        }
    }
    
    
    func printPretty() -> String {
        var output = "\n"
        output += devices
        output += printTotalMetric(Metric.WORK, value: totalTimeWork)
        output += printTotalMetric(Metric.VIEWSHED, value: totalTimeViewshed)
        output += printIndividualMetric(Metric.VIEWSHED)
        output += printTotalMetric(Metric.OVERLAY, value: totalTimeOverlay)
        output += printIndividualMetric(Metric.OVERLAY)
        output += printTotalMetric(Metric.Data.READING, value: totalTimeReadingData)
        output += printIndividualMetric(Metric.Data.READING)
        output += printTotalMetric(Metric.Data.SENDING, value: totalTimeSendingData)
        output += printIndividualMetric(Metric.Data.SENDING)
        output += printTotalMetric(Metric.Data.MERGING, value: totalTimeMergingData)
        output += printIndividualMetric(Metric.Data.MERGING)
        output += printPrettyOverallTime()
        
        return output
    }
    
    
    private func printPrettyOverallTime() -> String {
        var output = "Total Overall Time: "
        output += formatTime(self.overall.getElapsed())
        output += " seconds \n"

        return output
    }
    
    
    private func printTotalMetric(key: String, value: CFAbsoluteTime) -> String {
        var output = "\t\(key)\t\(formatTime(value)) seconds ("
        output += getPercentage(value, total: self.overall.getElapsed())
        output += " of Overall Time)\n"
        
        return output
    }

    
    private func printIndividualMetric(key: String) -> String {
        var output = ""

        if key == Metric.VIEWSHED {
            for (device, value) in individualTimeViewshed.getMetrics() {
                output = "\t\t\(device): \(formatTime(value)) seconds  ("
                output += self.getPercentage(value, total: totalTimeViewshed)
                output += " of \(key))\n"
            }
        } else if key == Metric.OVERLAY {
            for (device, value) in individualTimeOverlay.getMetrics() {
                output = "\t\t\(device): \(formatTime(value)) seconds  ("
                output += self.getPercentage(value, total: totalTimeOverlay)
                output += " of \(key))\n"
            }
        } else if key == Metric.Data.READING {
            for (device, value) in individualTimeReadingData.getMetrics() {
                output = "\t\t\(device): \(formatTime(value)) seconds  ("
                output += self.getPercentage(value, total: totalTimeReadingData)
                output += " of \(key))\n"
            }
        } else if key == Metric.Data.SENDING {
            for (device, value) in individualTimeSendingData.getMetrics() {
                output = "\t\t\(device): \(formatTime(value)) seconds  ("
                output += self.getPercentage(value, total: totalTimeSendingData)
                output += " of \(key))\n"
            }
        } else if key == Metric.Data.MERGING {
            for (device, value) in individualTimeMergingData.getMetrics() {
                output = "\t\t\(device): \(formatTime(value)) seconds  ("
                output += self.getPercentage(value, total: totalTimeMergingData)
                output += " of \(key))\n"
            }
        }
        output += "\n"
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