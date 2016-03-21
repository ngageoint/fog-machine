//
//  Work.swift
//  FogMachine
//
//  Created by Chris Wasko on 11/30/15.
//  Copyright © 2015 NGA. All rights reserved.
//

import Foundation


public class Work: MPCSerializable {
    
    public var metrics = [String:Timer]()
    
    public var mpcSerialized : NSData {
        let metricsData = encodeDictionary(metrics)
        let result = NSKeyedArchiver.archivedDataWithRootObject([
            Fog.METRICS: metricsData])
        
        return result
    }
    
    
    public init () {
    }
    
    
    public required init (mpcSerialized: NSData) {
        let workData = NSKeyedUnarchiver.unarchiveObjectWithData(mpcSerialized) as! [String: NSObject]
        metrics = decodeDictionary(workData[Fog.METRICS] as! NSData)
    }
    
    
    public func encodeDictionary(dictionary: [String: Timer]) -> NSData {
        var jsonData = NSData()
        var encodedDictionary = [String: [String: String]]()
        
        for (key, value) in dictionary {
            encodedDictionary.updateValue(value.encodeTimer(), forKey: key)
        }
        
        do {
            jsonData = try NSJSONSerialization.dataWithJSONObject(encodedDictionary, options: NSJSONWritingOptions.PrettyPrinted)
        } catch let error as NSError {
            print(error)
        }
        
        return jsonData
    }
    
    
    public func decodeDictionary(json: NSData) -> [String: Timer] {
        var decoded = [String: Timer]()
        do {
            let decodedDictionary = try NSJSONSerialization.JSONObjectWithData(json, options: []) as! [String: [String: String]]
            
            for (key, value) in decodedDictionary {
                decoded.updateValue(Timer(decodeTimerDictionary: value), forKey: key)
            }
        } catch let error as NSError {
            print(error)
        }
        
//        do {
//            if let response:NSDictionary = try NSJSONSerialization.JSONObjectWithData(json, options:NSJSONReadingOptions.MutableContainers) as? Dictionary<String, Timer> {
//                decoded = response as! [String: Timer]
//                dump(decoded)
//            } else {
//                print("Failed...")
//            }
//        } catch let serializationError as NSError {
//            print(serializationError)
//        }
        
        return decoded
    }
    
}
