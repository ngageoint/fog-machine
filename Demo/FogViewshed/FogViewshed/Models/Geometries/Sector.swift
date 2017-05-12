import Foundation
import MapKit

/**
 
 Class used to represent a sector
 
 */
class Sector: CustomStringConvertible {
    
    fileprivate var center: CLLocationCoordinate2D
    // from +x axis
    fileprivate var startAngleInRadans: Double
    // from +x axis
    fileprivate var endAngleInRadans: Double
    fileprivate var radiusInMeters: Double
    
    var description: String{
        return "(\(getCenter().latitude), \(getCenter().longitude))"
    }
    
    init(center: CLLocationCoordinate2D, startAngleInRadans: Double, endAngleInRadans: Double, radiusInMeters: Double) {
        self.center = center
        self.startAngleInRadans = startAngleInRadans
        self.endAngleInRadans = endAngleInRadans
        self.radiusInMeters = radiusInMeters
    }
    
    func getCenter() -> CLLocationCoordinate2D {
        return center
    }

    fileprivate func angleInRadiansToBearingInDegrees(_ angle: Double) -> Double {
        // convert the angle to a bearing
        return ((90 - GeoUtility.radianToDegree(angle)) + 360).truncatingRemainder(dividingBy: 360)
    }
    
    func getStartPosition() -> CLLocationCoordinate2D {
        let (lat, lon): (Double, Double) = GeoUtility.haversineDistanceInMeters(center.latitude, lon1: center.longitude, bearingInDegrees: angleInRadiansToBearingInDegrees(startAngleInRadans), distanceInMeters: radiusInMeters)
        return CLLocationCoordinate2DMake(lat,lon)
    }
    
    func getEndPosition() -> CLLocationCoordinate2D {
        let (lat, lon): (Double, Double) = GeoUtility.haversineDistanceInMeters(center.latitude, lon1: center.longitude, bearingInDegrees: angleInRadiansToBearingInDegrees(endAngleInRadans), distanceInMeters: radiusInMeters)
        return CLLocationCoordinate2DMake(lat,lon)
    }
    
    func getBoundingBox() -> AxisOrientedBoundingBox {
        
        var lats: [Double] = []
        var lons: [Double] = []
        
        var minLat: Double = center.latitude
        var minLon: Double = center.longitude

        var maxLat: Double = center.latitude
        var maxLon: Double = center.longitude
        
        lats.append(getStartPosition().latitude)
        lons.append(getStartPosition().longitude)

        lats.append(getEndPosition().latitude)
        lons.append(getEndPosition().longitude)
        
        // add min and max parts of the circle if we need to
        var angle: Double = 0
        for _ in 0..<4 {
            if(angle <= endAngleInRadans && angle > startAngleInRadans) {
                let (lat, lon): (Double, Double) = GeoUtility.haversineDistanceInMeters(center.latitude, lon1: center.longitude, bearingInDegrees: angleInRadiansToBearingInDegrees(angle), distanceInMeters: radiusInMeters)
                lats.append(lat)
                lons.append(lon)
            }
            angle += (Double.pi / 2)
        }
        
        
        for lat in lats {
            if(lat < minLat) {
                minLat = lat
            }
            if(lat > maxLat) {
                maxLat = lat
            }
        }
        for lon in lons {
            if(lon < minLon) {
                minLon = lon
            }
            if(lon > maxLon) {
                maxLon = lon
            }
        }
        
        return AxisOrientedBoundingBox(lowerLeft: CLLocationCoordinate2DMake(minLat, minLon), upperRight: CLLocationCoordinate2DMake(maxLat, maxLon))
    }
}
