import Foundation
import Fog

class ViewshedMetrics: MetricManager {
    
    
    // Used for processing the Metrics
    var totalManager = [String: CFAbsoluteTime]() // [Metric Name : Time]
    var individualManager = [String: Metrics<Node, CFAbsoluteTime>]() // [Metric Name: Metrics<Device Node, Time>]

    
    override func initialize() {
        super.initialize()
        self.totalManager.removeAll()
        self.individualManager.removeAll()
    }
    
    
    func processMetrics() {
        for (aNode, deviceMetrics) in storedMetrics.getMetrics() {
            devices += "\t\t\(aNode.name)\n"
            for (event, timer) in deviceMetrics.getMetrics() {
                addToTotal(event, value: timer.getElapsedTimeInSeconds())
                addToIndividual(event, metricKey: aNode, metricValue: timer.getElapsedTimeInSeconds())
            }
        }
    }

    
//    func getOutput() -> String {
//        var output = "\n"
//        output += self.devices
//        output += "\n"
//        output += getOverallTime()
//        output += "\n\nStep Breakdown:\n"
//        
//        for key in Metric.OUTPUT_ORDER {
//            var metricOutput = ""
//            metricOutput += getTotalTimeForKey(key)
//            metricOutput += getIndividualTimesForKey(key)
//            if metricOutput != "" {
//                output += metricOutput
//                output += "\n"
//            }
//        }
//
//        output += "\n"
//
//        return output
//    }
    
    
    // MARK: Process - Private Functions

    
    private func addToTotal(key: String, value: CFAbsoluteTime) {
        guard let oldValue = totalManager[key] else {
            totalManager.updateValue(value, forKey: key)
            return
        }
        
        let newValue = value + oldValue
        totalManager.updateValue(newValue, forKey: key)
    }
    
    
    private func addToIndividual(key: String, metricKey: Node, metricValue: CFAbsoluteTime) {
        guard let updateValue = individualManager[key] else {
            let newValue = Metrics<Node, CFAbsoluteTime>()
            newValue.updateValue(metricValue, forKey: metricKey)
            individualManager.updateValue(newValue, forKey: key)
            return
        }
        
        updateValue.updateValue(metricValue, forKey: metricKey)
        individualManager.updateValue(updateValue, forKey: key)
    }
    
    
    private func getOverallTime() -> String {
        var output = "Total Time: "
        output += formatTime(self.overall.getElapsedTimeInSeconds())
        output += "s"

        return output
    }
    
    
    private func getTotalTimeForKey(key: String) -> String {
        guard let value = totalManager[key] else {
            return ""
        }
        
        var output = "\t\(key):\n\t\t\t\(formatTime(value))s ("
        output += getPercentage(value, total: self.overall.getElapsedTimeInSeconds())
        output += " of Total Time)\n"
        
        return output
    }

    
//    private func getIndividualTimesForKey(key: String) -> String {
//        guard let individualMetrics = individualManager[key] else {
//            return ""
//        }
//        guard let totalValue = totalManager[key] else {
//            return ""
//        }
//        
//        var output = ""
//        var printableKey = key
//        let parsedKey = key.componentsSeparatedByString(Metric.DELIMITER)
//        if parsedKey.count >= 2 {
//            printableKey = parsedKey[1]
//        }
//        for (aNode, time) in individualMetrics.getMetrics() {
//            output += "\t\t\(aNode.name):\n\t\t\t\(formatTime(time))s ("
//            output += self.getPercentage(time, total: totalValue)
//            output += " of \(printableKey))\n"
//        }
//
//        return output
//    }
    
    
    private func getPercentage(value: CFAbsoluteTime, total: CFAbsoluteTime) -> String {
        let percentage: Double = (value / total) * 100.0

        return "\(String(format: "%.1f", percentage))%"
    }
    
    
    private func formatTime(time: CFAbsoluteTime) -> String {
        return String(format: "%.3f", time)
    }
    
}