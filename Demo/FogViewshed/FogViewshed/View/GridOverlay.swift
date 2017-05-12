import UIKit
import MapKit

class GridOverlay: NSObject, MKOverlay {
    
    var coordinate: CLLocationCoordinate2D
    var boundingMapRect: MKMapRect
    var image: UIImage
    
    init(midCoordinate: CLLocationCoordinate2D, overlayBoundingMapRect: MKMapRect, viewshedImage: UIImage) {
        boundingMapRect = overlayBoundingMapRect
        coordinate = midCoordinate
        image = viewshedImage
    }
}
