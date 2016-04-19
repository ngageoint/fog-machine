import Foundation

public class Timer {
    
    var startTime: CFAbsoluteTime
    var stopTime: CFAbsoluteTime
    
    public init() {
        startTime = CFAbsoluteTimeGetCurrent()
        stopTime = CFAbsoluteTimeGetCurrent()
    }
    
    // MARK: Functions
    
    
    public func start() {
        startTime = CFAbsoluteTimeGetCurrent()
        stopTime = CFAbsoluteTimeGetCurrent()
    }
    
    public func stop() -> CFAbsoluteTime {
        stopTime = CFAbsoluteTimeGetCurrent()
        return getElapsedTimeInSeconds()
    }
    
    public func getElapsedTimeInSeconds() -> CFAbsoluteTime {
        return stopTime - startTime
    }
}