import Foundation
import MapKit

// This class does geospatial stuff
class GeoUtility {
    
    private static let a = 6378137.0; // WGS-84 geoidal semi-major axis of earth in meters
    private static let e:Double = 8.1819190842622e-2;  // eccentricity
    private static let asq:Double = a * GeoUtility.a;
    private static let esq:Double = GeoUtility.e * GeoUtility.e;
    
    private static let b:Double = sqrt(asq * (1 - esq)); // WGS-84 geoidal semi-minor axis of earth in meters
    
    static func degreeToRadian(degrees: Double) -> Double {
        return M_PI * degrees / 180.0;
    }
    
    static func radianToDegree(radians: Double) -> Double {
        return 180.0 * radians / M_PI;
    }
    
    // Earth radius at a given latitude, according to the WGS-84 ellipsoid in meters
    static func earthRadiusAtLat(lat: Double) -> Double {
        let An = asq * cos(lat);
        let Bn = b * b * sin(lat);
        let Ad = a * cos(lat);
        let Bd = b * sin(lat);
        
        return sqrt((An*An + Bn*Bn) / (Ad*Ad + Bd*Bd));
    }
    
}
