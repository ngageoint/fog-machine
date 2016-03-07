//
//  Box.swift
//  FogViewshed
//
//  Created by Chris Wasko on 3/4/16.
//  Copyright © 2016 NGA. All rights reserved.
//

import Foundation
import MapKit

class Box {
    
    var upperLeft: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0.0, 0.0)
    var upperRight: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0.0, 0.0)
    var lowerLeft: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0.0, 0.0)
    var lowerRight: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0.0, 0.0)

    
    func getOrderedCorners() -> [CLLocationCoordinate2D] {
        return [upperLeft,
                upperRight,
                lowerLeft,
                lowerRight]
    }
    
}