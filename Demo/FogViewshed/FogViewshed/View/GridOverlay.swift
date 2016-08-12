import UIKit
import MapKit

class GridOverlay: NSObject, MKOverlay {
    var coordinate: CLLocationCoordinate2D
    var boundingMapRect: MKMapRect
    var image: UIImage
    var rawElevation: [[Int]]
    var elevationCoordinate: CLLocationCoordinate2D
    
    init(midCoordinate: CLLocationCoordinate2D, overlayBoundingMapRect: MKMapRect, viewshedImage: UIImage, rawElevation: [[Int]], elevationCoordinate: CLLocationCoordinate2D) {
        boundingMapRect = overlayBoundingMapRect
        coordinate = midCoordinate
        image = viewshedImage
        self.rawElevation = rawElevation
        self.elevationCoordinate = elevationCoordinate
    }
}