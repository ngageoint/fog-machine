//
//  Box.swift
//  FogViewshed
//
//  Created by Chris Wasko on 3/4/16.
//  Copyright © 2016 NGA. All rights reserved.
//

import Foundation
import MapKit


class AxisOrientedBoundingBox {
    
    private var lowerLeft: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0.0, 0.0)
    private var upperRight: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0.0, 0.0)
    
    func getLowerLeft() -> CLLocationCoordinate2D {
        return lowerLeft
    }
    
    func getUpperRight() -> CLLocationCoordinate2D {
        return upperRight
    }

    func getLowerRight() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(lowerLeft.latitude, upperRight.longitude)
    }

    func getUpperLeft() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(upperRight.latitude, lowerLeft.longitude)
    }
    
    static func getBoundingBox(point: CLLocationCoordinate2D, radius: Double) -> AxisOrientedBoundingBox  {
        
        // Bounding box surrounding the point at given coordinates,
        // assuming local approximation of Earth surface as a sphere
        // of radius given by WGS84
        let lat = GeoUtility.degreeToRadian(point.latitude)
        let lon = GeoUtility.degreeToRadian(point.longitude)
        
        let eradius = GeoUtility.earthRadiusAtLat(lat)
        // Radius of the parallel at given latitude
        let pradius = eradius * cos(lat)
        
        let latMin = lat - radius / eradius
        let latMax = lat + radius / eradius
        let lonMin = lon - radius / pradius
        let lonMax = lon + radius / pradius
        
        let axisOrientedBoundingBox = AxisOrientedBoundingBox()
        axisOrientedBoundingBox.lowerLeft = CLLocationCoordinate2DMake(GeoUtility.radianToDegree(latMin), GeoUtility.radianToDegree(lonMin))
        axisOrientedBoundingBox.upperRight = CLLocationCoordinate2DMake(GeoUtility.radianToDegree(latMax), GeoUtility.radianToDegree(lonMax))
        
        return axisOrientedBoundingBox
    }
    
    // TODO : remove me, keeping for compatibility
    func getOrderedCorners() -> [CLLocationCoordinate2D] {
        return [getUpperLeft(), // upper left
                upperRight,
                lowerLeft,
                getLowerRight()] // lower right
    }
}