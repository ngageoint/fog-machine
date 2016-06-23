import Foundation

/**
 
 A Utility to help time requests and responses in FogMachine
 
 */
public class FMTimer {
    
    var startTime: CFAbsoluteTime
    var stopTime: CFAbsoluteTime
    var stopped: Bool = false
    
    public init() {
        stopped = false;
        startTime = CFAbsoluteTimeGetCurrent()
        stopTime = Double(startTime)
    }
    
    // MARK: Functions
    
    public func start() {
        stopped = false;
        startTime = CFAbsoluteTimeGetCurrent()
        stopTime = Double(startTime)
    }
    
    public func stop() -> CFAbsoluteTime {
        stopTime = CFAbsoluteTimeGetCurrent()
        stopped = true;
        return getElapsedTimeInSeconds()
    }
    
    public func getElapsedTimeInSeconds() -> CFAbsoluteTime {
        if(stopped) {
            return stopTime - startTime
        } else {
            return CFAbsoluteTimeGetCurrent() - startTime
        }
    }
}