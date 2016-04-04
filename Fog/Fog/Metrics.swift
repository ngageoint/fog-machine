import Foundation


public class Metrics<K: Hashable, V> {

    var metrics: [K: V]
    
    
    public init() {
        self.metrics = [K: V]()
    }
    
    
    public func getValue(key: K) -> V? {
        return metrics[key]
    }
    
    public func updateValue(value: V, forKey: K) {
        metrics.updateValue(value, forKey: forKey)
    }
    
    
    public func removeValueForKey(key: K) {
        metrics.removeValueForKey(key)
    }
   
    
    public func getMetrics() -> [K: V] {
        return metrics
    }
    
}