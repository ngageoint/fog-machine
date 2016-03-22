//
//  Timer.swift
//  Fog
//
//  Created by Chris Wasko on 3/18/16.
//  Copyright © 2016 NGA. All rights reserved.
//

import Foundation


public class Timer {
    
    
    var start: CFAbsoluteTime!
    var end: CFAbsoluteTime!
    var elapsed: CFAbsoluteTime!
    
    
    public init() {
    }
    
    
    public init(decodeTimerDictionary: [String: String]) {
        self.start = CFAbsoluteTime(decodeTimerDictionary[Metric.START]!)
        self.end = CFAbsoluteTime(decodeTimerDictionary[Metric.END]!)
        self.elapsed = CFAbsoluteTime(decodeTimerDictionary[Metric.ELAPSED]!)
    }

    
    // MARK: Functions
    
    
    public func startTimer() {
        start = CFAbsoluteTimeGetCurrent()
    }
    
    
    public func stopTimer() -> CFAbsoluteTime {
        end = CFAbsoluteTimeGetCurrent()
        elapsed = end - start
        return elapsed
    }
    
    
    public func clear() {
        start = 0
        end = 0
        elapsed = 0
    }
    
    
    public func encodeTimer() -> [String: String] {
        var timerDictionary = [String: String]()
        
        timerDictionary.updateValue(String(start), forKey: Metric.START)
        timerDictionary.updateValue(String(end), forKey: Metric.END)
        timerDictionary.updateValue(String(elapsed), forKey: Metric.ELAPSED)
        
        return timerDictionary
    }
    
    
    public func printPretty(indent: String = "") -> String {
        return "\(indent)Start \(start)\n\(indent)End \(end)\n\(indent)Elapsed \(elapsed)"
    }
    
    
    public func getStart() -> CFAbsoluteTime {
        return start
    }

    
    public func getEnd() -> CFAbsoluteTime {
        return end
    }

    
    public func getElapsed() -> CFAbsoluteTime {
        return elapsed
    }

}