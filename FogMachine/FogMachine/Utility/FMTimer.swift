import Foundation

/**
 
 A Utility to help time requests and responses in FogMachine
 
 */
public class FMTimer {
    
    private var startTime: CFAbsoluteTime
    private var stopTime: CFAbsoluteTime
    private var stopped: Bool = false
    
    public init() {
        stopped = false;
        startTime = CFAbsoluteTimeGetCurrent()
        stopTime = Double(startTime)
    }
    
    // MARK: Functions
    
    /**
     Start the timer
     */
    public func start() {
        stopped = false;
        startTime = CFAbsoluteTimeGetCurrent()
        stopTime = Double(startTime)
    }

    /**
     Stop the timer
     
     - returns: the elapsed time in seconds
     */
    public func stop() -> CFAbsoluteTime {
        stopTime = CFAbsoluteTimeGetCurrent()
        stopped = true;
        return getElapsedTimeInSeconds()
    }
    
    /**
     Get the elapsed time in seconds
     
     - returns: the elapsed time in seconds
     */
    public func getElapsedTimeInSeconds() -> CFAbsoluteTime {
        if(stopped) {
            return stopTime - startTime
        } else {
            return CFAbsoluteTimeGetCurrent() - startTime
        }
    }
}