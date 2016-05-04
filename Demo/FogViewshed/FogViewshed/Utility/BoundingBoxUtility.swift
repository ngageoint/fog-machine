import Foundation
import MapKit

class BoundingBoxUtility {
    static func getBoundingBox(center: CLLocationCoordinate2D, radiusInMeters: Double) -> AxisOrientedBoundingBox  {
        // Bounding box surrounding the point at given coordinates, assuming local approximation of Earth surface as a sphere of radius given by WGS84
        let lat = GeoUtility.degreeToRadian(center.latitude)
        let lon = GeoUtility.degreeToRadian(center.longitude)
        
        let eradius = GeoUtility.earthRadiusAtLat(lat)
        // Radius of the parallel at given latitude
        let pradius = eradius * cos(lat)
        
        let latMin = lat - radiusInMeters / eradius
        let latMax = lat + radiusInMeters / eradius
        let lonMin = lon - radiusInMeters / pradius
        let lonMax = lon + radiusInMeters / pradius
        
        let lowerLeft: CLLocationCoordinate2D  = CLLocationCoordinate2DMake(GeoUtility.radianToDegree(latMin), GeoUtility.radianToDegree(lonMin))
        let upperRight: CLLocationCoordinate2D = CLLocationCoordinate2DMake(GeoUtility.radianToDegree(latMax), GeoUtility.radianToDegree(lonMax))
        let axisOrientedBoundingBox = AxisOrientedBoundingBox(lowerLeft: lowerLeft, upperRight: upperRight)
        
        return axisOrientedBoundingBox
    }
    
    // FIXME
//    static func getBoundingBox(sectorSTUFF ::: CLLocationCoordinate2D, radiusInMeters: Double) -> AxisOrientedBoundingBox  {
//        // Bounding box surrounding the point at given coordinates, assuming local approximation of Earth surface as a sphere of radius given by WGS84
//        let lat = GeoUtility.degreeToRadian(center.latitude)
//        let lon = GeoUtility.degreeToRadian(center.longitude)
//        
//        let eradius = GeoUtility.earthRadiusAtLat(lat)
//        // Radius of the parallel at given latitude
//        let pradius = eradius * cos(lat)
//        
//        let latMin = lat - radius / eradius
//        let latMax = lat + radius / eradius
//        let lonMin = lon - radius / pradius
//        let lonMax = lon + radius / pradius
//        
//        let lowerLeft: CLLocationCoordinate2D  = CLLocationCoordinate2DMake(GeoUtility.radianToDegree(latMin), GeoUtility.radianToDegree(lonMin))
//        let upperRight: CLLocationCoordinate2D = CLLocationCoordinate2DMake(GeoUtility.radianToDegree(latMax), GeoUtility.radianToDegree(lonMax))
//        let axisOrientedBoundingBox = AxisOrientedBoundingBox(lowerLeft: lowerLeft, upperRight: upperRight)
//        
//        return axisOrientedBoundingBox
//    }
}
