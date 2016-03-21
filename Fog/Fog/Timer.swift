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
        self.start = CFAbsoluteTime(decodeTimerDictionary[Metrics.START]!)
        self.end = CFAbsoluteTime(decodeTimerDictionary[Metrics.END]!)
        self.elapsed = CFAbsoluteTime(decodeTimerDictionary[Metrics.ELAPSED]!)
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
        
        timerDictionary.updateValue(String(start), forKey: Metrics.START)
        timerDictionary.updateValue(String(end), forKey: Metrics.END)
        timerDictionary.updateValue(String(elapsed), forKey: Metrics.ELAPSED)
        
        return timerDictionary
    }
    
}