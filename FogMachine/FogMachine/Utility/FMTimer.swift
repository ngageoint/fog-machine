import Foundation

/**
 
 A Utility to help time requests and responses in FogMachine
 
 */
open class FMTimer {
    
    fileprivate var startTime: CFAbsoluteTime
    fileprivate var stopTime: CFAbsoluteTime
    fileprivate var stopped: Bool = false
    
    public init() {
        stopped = false
        startTime = CFAbsoluteTimeGetCurrent()
        stopTime = Double(startTime)
    }
    
    // MARK: Functions
    
    /**
     Start the timer
     */
    open func start() {
        stopped = false
        startTime = CFAbsoluteTimeGetCurrent()
        stopTime = Double(startTime)
    }

    /**
     Stop the timer
     
     - returns: the elapsed time in seconds
     */
    open func stop() -> CFAbsoluteTime {
        stopTime = CFAbsoluteTimeGetCurrent()
        stopped = true
        return getElapsedTimeInSeconds()
    }
    
    /**
     Get the elapsed time in seconds
     
     - returns: the elapsed time in seconds
     */
    open func getElapsedTimeInSeconds() -> CFAbsoluteTime {
        if(stopped) {
            return stopTime - startTime
        } else {
            return CFAbsoluteTimeGetCurrent() - startTime
        }
    }
}
