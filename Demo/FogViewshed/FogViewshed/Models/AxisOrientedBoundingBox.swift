import Foundation
import MapKit

class AxisOrientedBoundingBox {
    
    private var lowerLeft: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0.0, 0.0)
    private var upperRight: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0.0, 0.0)
    
    init(lowerLeft: CLLocationCoordinate2D, upperRight: CLLocationCoordinate2D) {
        self.lowerLeft = lowerLeft;
        self.upperRight = upperRight;
    }
    
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
    
    func intersectionExists(with:AxisOrientedBoundingBox) -> Bool {
        let aURLat = getUpperRight().latitude
        let aURLon = getUpperRight().longitude
        
        let bLLLat = with.getLowerLeft().latitude
        let bLLLon = with.getLowerLeft().longitude
        
        let aLLLat = getLowerLeft().latitude
        let aLLLon = getLowerLeft().longitude
        
        let bURLat = with.getUpperRight().latitude
        let bURLon = with.getUpperRight().longitude
        
        if(bLLLat < aURLat && bLLLon < aURLon && aLLLat < bURLat && aLLLon < bURLon) {
            return true
        }
        return false
    }
    
    // you should check if there is an intersection with isIntersection before calling this function!
    func intersection(with:AxisOrientedBoundingBox) -> AxisOrientedBoundingBox {
        let llLat:Double = max(getLowerLeft().latitude, with.getLowerLeft().latitude);
        let llLon:Double = max(getLowerLeft().longitude, with.getLowerLeft().longitude);
        
        let urLat:Double = min(getUpperRight().latitude, with.getUpperRight().latitude);
        let urLon:Double = min(getUpperRight().longitude, with.getUpperRight().longitude);
        
        return AxisOrientedBoundingBox(lowerLeft: CLLocationCoordinate2DMake(llLat, llLon), upperRight: CLLocationCoordinate2DMake(urLat, urLon))
    }
}