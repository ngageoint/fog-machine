//
//  Work.swift
//  FogMachine
//
//  Created by Chris Wasko on 11/30/15.
//  Copyright © 2015 NGA. All rights reserved.
//

import Foundation


public class Work: MPCSerializable {

    var serializedFogMetrics = Metrics<String, Timer>()
    var workerName: String = ConnectionManager.selfNode().displayName

    public var mpcSerialized : NSData {
        let metricsData = encodeDictionary(gatherGlobalFogMetrics())
        let result = NSKeyedArchiver.archivedDataWithRootObject([
            Fog.WORKER_NAME: workerName,
            Fog.METRICS: metricsData])

        return result
    }


    public init () {
    }


    public required init (mpcSerialized: NSData) {
        let workData = NSKeyedUnarchiver.unarchiveObjectWithData(mpcSerialized) as! [String: NSObject]
        serializedFogMetrics = decodeDictionary(workData[Fog.METRICS] as! NSData)
        workerName = workData[Fog.WORKER_NAME] as! String
        fogMetrics.mergeValueWithExisting(serializedFogMetrics, deviceName: workerName)
    }


    public func encodeDictionary(dictionary: Metrics<String, Timer>) -> NSData {
        var jsonData = NSData()
        var encodedDictionary = [String: [String: String]]()

        for (key, value) in dictionary.getMetrics() {
            encodedDictionary.updateValue(value.encodeTimer(), forKey: key)
        }

        do {
            jsonData = try NSJSONSerialization.dataWithJSONObject(encodedDictionary, options: NSJSONWritingOptions.PrettyPrinted)
        } catch let error as NSError {
            print(error)
        }

        return jsonData
    }


    public func decodeDictionary(json: NSData) -> Metrics<String, Timer> {
        let decoded = Metrics<String, Timer>()
        do {
            let decodedDictionary = try NSJSONSerialization.JSONObjectWithData(json, options: []) as! [String: [String: String]]

            for (key, value) in decodedDictionary {
                decoded.updateValue(Timer(decodeTimerDictionary: value), forKey: key)
            }
        } catch let error as NSError {
            print(error)
        }

        return decoded
    }


    public func gatherGlobalFogMetrics() -> Metrics<String, Timer> {
        if let newMetrics = fogMetrics.getMetricsForDevice(workerName) {
            self.addFogMetrics(newMetrics)
        }
        return serializedFogMetrics
    }


    public func getFogMetrics() -> Metrics<String, Timer> {
        return serializedFogMetrics
    }

    public func getWorkerName() -> String {
        return workerName
    }

    func addFogMetrics(newMetrics: Metrics<String, Timer>) {
        for (key, time) in newMetrics.getMetrics() {
            serializedFogMetrics.updateValue(time, forKey: key)
        }
    }

}
