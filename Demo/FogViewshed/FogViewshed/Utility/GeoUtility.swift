import Foundation
import MapKit

// This class does geospatial stuff
class GeoUtility {

    private static let a = 6378137.0 // WGS-84 geoidal semi-major axis of earth in meters
    private static let e:Double = 8.1819190842622e-2  // eccentricity
    private static let asq:Double = a * a
    private static let esq:Double = e * e

    private static let b:Double = sqrt(asq * (1 - esq)) // WGS-84 geoidal semi-minor axis of earth in meters

    static func degreeToRadian(degrees: Double) -> Double {
        return M_PI * degrees / 180.0
    }

    static func radianToDegree(radians: Double) -> Double {
        return 180.0 * radians / M_PI
    }

    // Earth radius at a given latitude, according to the WGS-84 ellipsoid in meters
    static func earthRadiusAtLat(lat: Double) -> Double {
        let An = asq * cos(lat)
        let Bn = b * b * sin(lat)
        let Ad = a * cos(lat)
        let Bd = b * sin(lat)

        return sqrt((An*An + Bn*Bn) / (Ad*Ad + Bd*Bd))
    }

    // see http://www.movable-type.co.uk/scripts/latlong-vincenty.html
    static func vincentyDistanceInMeters(lat1:Double, lon1:Double, lat2:Double, lon2:Double) -> Double {
        let f:Double = 1 / 298.257223563
        let L:Double = degreeToRadian(lon2 - lon1)
        let U1:Double = atan((1 - f) * tan(degreeToRadian(lat1)))
        let U2:Double = atan((1 - f) * tan(degreeToRadian(lat2)))
        let sinU1:Double = sin(U1)
        let cosU1:Double = cos(U1)
        let sinU2:Double = sin(U2)
        let cosU2:Double = cos(U2)
        var cosSqAlpha:Double
        var sinSigma:Double
        var cos2SigmaM:Double
        var cosSigma:Double
        var sigma:Double

        var lambda:Double = L
        var lambdaP:Double
        var iterLimit:Double = 100
        repeat {
            let sinLambda:Double = sin(lambda)
            let cosLambda:Double = cos(lambda)
            sinSigma = sqrt(  (cosU2 * sinLambda) * (cosU2 * sinLambda) + (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda) * (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda))
            if (sinSigma == 0) {
                return 0
            }

            cosSigma = sinU1 * sinU2 + cosU1 * cosU2 * cosLambda
            sigma = atan2(sinSigma, cosSigma)
            let sinAlpha:Double = cosU1 * cosU2 * sinLambda / sinSigma
            cosSqAlpha = 1 - sinAlpha * sinAlpha
            cos2SigmaM = cosSigma - 2 * sinU1 * sinU2 / cosSqAlpha

            let C:Double = f / 16 * cosSqAlpha * (4 + f * (4 - 3 * cosSqAlpha))
            lambdaP = lambda
            lambda =   L + (1 - C) * f * sinAlpha * (sigma + C * sinSigma * (cos2SigmaM + C * cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM)))
            iterLimit = iterLimit - 1
        } while (abs(lambda - lambdaP) > 1e-12 && iterLimit > 0)

        if (iterLimit == 0) {
            return 0
        }

        let uSq:Double = cosSqAlpha * (a * a - b * b) / (b * b)
        let A:Double = 1 + uSq / 16384 * (4096 + uSq * (-768 + uSq * (320 - 175 * uSq)))
        let B:Double = uSq / 1024 * (256 + uSq * (-128 + uSq * (74 - 47 * uSq)))
        let deltaSigma:Double = B * sinSigma * (cos2SigmaM + B / 4 * (cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM) - B / 6 * cos2SigmaM * (-3 + 4 * sinSigma * sinSigma) * (-3 + 4 * cos2SigmaM * cos2SigmaM)))

        let s:Double = b * A * (sigma - deltaSigma)
        return s
    }

    // see https://rosettacode.org/wiki/Haversine_formula#Swift
    static func haversineDistanceInMeters(lat1:Double, lon1:Double, lat2:Double, lon2:Double) -> Double {
        let lat1rad:Double = degreeToRadian(lat1)
        let lon1rad:Double = degreeToRadian(lon1)
        let lat2rad:Double = degreeToRadian(lat2)
        let lon2rad:Double = degreeToRadian(lon2)

        let dLat:Double = lat2rad - lat1rad
        let dLon:Double = lon2rad - lon1rad
        let a:Double = sin(dLat/2) * sin(dLat/2) + sin(dLon/2) * sin(dLon/2) * cos(lat1rad) * cos(lat2rad)
        let c:Double = 2 * asin(sqrt(a))
        let R:Double = 6371000.0

        return R * c
    }
    
    // see http://stackoverflow.com/questions/7222382/get-lat-long-given-current-point-distance-and-bearing/7835325#7835325
    static func haversineDistanceInMeters(lat1:Double, lon1:Double, bearingInDegrees:Double, distanceInMeters:Double) -> (Double,Double) {
        let bearingInRadians:Double = degreeToRadian(bearingInDegrees)
        
        let lat1R:Double = degreeToRadian(lat1)
        let lon1R:Double = degreeToRadian(lon1)
        
        let R:Double = 6371000.0
        
        let lat2R:Double = asin( sin(lat1R)*cos(distanceInMeters/R) + cos(lat1R)*sin(distanceInMeters/R)*cos(bearingInRadians))
        let lon2R:Double = lon1R + atan2(sin(bearingInRadians)*sin(distanceInMeters/R)*cos(lat1R), cos(distanceInMeters/R)-sin(lat1R)*sin(lat2R))
        
        let lat2:Double = radianToDegree(lat2R)
        let lon2:Double = radianToDegree(lon2R)
        
        return (lat2,lon2)
    }
}
