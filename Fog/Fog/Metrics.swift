//
//  Metrics.swift
//  Fog
//
//  Created by Chris Wasko on 3/22/16.
//  Copyright © 2016 NGA. All rights reserved.
//

import Foundation


public class Metrics<K: Hashable, V> {

    var metrics: [K: V]
    
    
    public init() {
        self.metrics = [K: V]()
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