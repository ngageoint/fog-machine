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
    
    
    override var mpcSerialized : NSData {
        let metricsData = encodeDictionary(metrics)
        let result = NSKeyedArchiver.archivedDataWithRootObject(
            [FogViewshed.VIEWSHED_RESULT: viewshedResult,
                Fog.METRICS: metricsData])
        
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
    }

}

