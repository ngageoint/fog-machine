//
//  ViewshedResult.swift
//  FogMachine
//
//  Created by Chris Wasko on 11/24/15.
//  Copyright © 2015 NGA. All rights reserved.
//

import Foundation
import MapKit
import Fog

class ViewshedResult: Work {
    
    
    let viewshedResult:UIImage// UIImage//[[Int]]
    var serializedViewshedMetrics = Metrics<String, Timer>()
    
    override var mpcSerialized : NSData {
        if let newMetrics = viewshedMetrics.getMetricsForDevice(Worker.getMe().displayName) {
            self.addViewshedMetrics(newMetrics)
        }

        let viewshedMetricsData = encodeDictionary(getViewshedMetrics())
        let fogMetricsData = encodeDictionary(gatherGlobalFogMetrics())
        let result = NSKeyedArchiver.archivedDataWithRootObject(
            [FogViewshed.VIEWSHED_RESULT: viewshedResult,
                FogViewshed.METRICS: viewshedMetricsData,
                Fog.METRICS: fogMetricsData])

        return result
    }
    
    
    init (viewshedResult: UIImage) { //UIImage) { //[[Int]]) {
        self.viewshedResult = viewshedResult
        super.init()
    }
    
    
    required init (mpcSerialized: NSData) {
        let workData = NSKeyedUnarchiver.unarchiveObjectWithData(mpcSerialized) as! [String: NSObject]
        viewshedResult = workData[FogViewshed.VIEWSHED_RESULT] as! UIImage //UIImage//[[Int]]
        super.init(mpcSerialized: mpcSerialized)
        serializedViewshedMetrics = decodeDictionary(workData[FogViewshed.METRICS] as! NSData)
    }
    
    
    func addViewshedMetrics(newMetrics: Metrics<String, Timer>) {
        for (key, time) in newMetrics.getMetrics() {
            serializedViewshedMetrics.updateValue(time, forKey: key)
        }
    }
    
    
    func getViewshedMetrics() -> Metrics<String, Timer> {
        return serializedViewshedMetrics
    }

}

