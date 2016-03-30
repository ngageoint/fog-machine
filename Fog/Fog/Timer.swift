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
        start = -1
        end = -1
        elapsed = -1
    }
    
    
    public init(decodeTimerDictionary: [String: String]) {
        self.start = CFAbsoluteTime(decodeTimerDictionary[Time.START]!)
        self.end = CFAbsoluteTime(decodeTimerDictionary[Time.END]!)
        self.elapsed = CFAbsoluteTime(decodeTimerDictionary[Time.ELAPSED]!)
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
        start = -1
        end = -1
        elapsed = -1
    }
    
    
    public func encodeTimer() -> [String: String] {
        var timerDictionary = [String: String]()
        
        timerDictionary.updateValue(String(start), forKey: Time.START)
        timerDictionary.updateValue(String(end), forKey: Time.END)
        timerDictionary.updateValue(String(elapsed), forKey: Time.ELAPSED)
        
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

    
    public func setStart(start: CFAbsoluteTime) {
        self.start = start
    }
    
    
    public func setEnd(end: CFAbsoluteTime) {
        self.end = end
    }
    
    
    public func calculateElapsed() {
        elapsed = end - start
    }
    
}