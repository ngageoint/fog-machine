//
//  BoundingBox.swift
//  FogViewshed
//
//  Created by Chris Wasko on 3/4/16.
//  Copyright © 2016 NGA. All rights reserved.
//

import Foundation
import MapKit


class BoundingBox {
    
    //Adopted from: http://stackoverflow.com/a/14314146
    
    // Semi-axes of WGS-84 geoidal reference
    let WGS84_a = 6378137.0; // Major semiaxis in meters
    let WGS84_b = 6356752.314245; // Minor semiaxis in meters
    

    func getBoundingBox(observer: Observer) -> Box  {
        let point = observer.getObserverLocation()
        
        // Bounding box surrounding the point at given coordinates,
        // assuming local approximation of Earth surface as a sphere
        // of radius given by WGS84
        let lat = degreeToRadian(point.latitude);
        let lon = degreeToRadian(point.longitude);
        // Half of a side of the bounding box
        let halfSide = Double(observer.getRadius())
        
        let radius = earthRadiusWgs84(lat);
        // Radius of the parallel at given latitude
        let pradius = radius * cos(lat);

        let latMin = lat - halfSide / radius;
        let latMax = lat + halfSide / radius;
        let lonMin = lon - halfSide / pradius;
        let lonMax = lon + halfSide / pradius;
        
        let boundBox = Box()
        boundBox.lowerLeft = CLLocationCoordinate2DMake(radianToDegree(latMin), radianToDegree(lonMin))
        boundBox.upperRight = CLLocationCoordinate2DMake(radianToDegree(latMax), radianToDegree(lonMax))
        boundBox.upperLeft = CLLocationCoordinate2DMake(radianToDegree(latMax), radianToDegree(lonMin))
        boundBox.lowerRight = CLLocationCoordinate2DMake(radianToDegree(latMin), radianToDegree(lonMax))
        
        return boundBox
    }
    

    func degreeToRadian(degrees: Double) -> Double {
        return M_PI * degrees / 180.0;
    }
    

    func radianToDegree(radians: Double) -> Double {
        return 180.0 * radians / M_PI;
    }
    
    // Earth radius at a given latitude, according to the WGS-84 ellipsoid in meters
    func earthRadiusWgs84(lat: Double) -> Double {
        // http://en.wikipedia.org/wiki/Earth_radius
        let An = WGS84_a * WGS84_a * cos(lat);
        let Bn = WGS84_b * WGS84_b * sin(lat);
        let Ad = WGS84_a * cos(lat);
        let Bd = WGS84_b * sin(lat);
        
        return sqrt((An*An + Bn*Bn) / (Ad*Ad + Bd*Bd));
    }
    
}
