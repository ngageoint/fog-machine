import Foundation
import MapKit
import FogMachine

public class ViewshedWork: FMWork {
    
    let numberOfQuadrants: Int
    let whichQuadrant: Int
    
    // Observer properties
    let name: String
    let xCoord:Int
    let yCoord:Int
    let elevation:Int
    let radius:Int
    let latitude: Double
    let longitude: Double
    let algorithm: Int

    init (numberOfQuadrants: Int, whichQuadrant: Int, observer: Observer) {
        self.numberOfQuadrants = numberOfQuadrants
        self.whichQuadrant = whichQuadrant
        
        self.name = observer.name
        self.xCoord = observer.xCoord
        self.yCoord = observer.yCoord
        self.elevation = observer.elevation
        self.radius = observer.getRadius()
        self.latitude = observer.coordinate.latitude
        self.longitude = observer.coordinate.longitude
        self.algorithm = observer.algorithm.rawValue
        super.init()
    }
    
    
    func getObserver() -> Observer {
        return Observer(name: name, xCoord: xCoord, yCoord: yCoord, elevation: elevation, radius: radius, coordinate: CLLocationCoordinate2DMake(latitude, longitude))
    }
    
    required public init(coder decoder: NSCoder) {
        self.numberOfQuadrants = decoder.decodeIntegerForKey("numberOfQuadrants")
        self.whichQuadrant = decoder.decodeIntegerForKey("whichQuadrant")
        
        self.name = decoder.decodeObjectForKey("name") as! String
        self.xCoord = decoder.decodeIntegerForKey("xCoord")
        self.yCoord = decoder.decodeIntegerForKey("yCoord")
        self.elevation = decoder.decodeIntegerForKey("elevation")
        self.radius = decoder.decodeIntegerForKey("radius")
        self.latitude = decoder.decodeDoubleForKey("latitude")
        self.longitude = decoder.decodeDoubleForKey("longitude")
        self.algorithm = decoder.decodeIntegerForKey("algorithm")
        
        super.init(coder: decoder)
    }
    
    public override func encodeWithCoder(coder: NSCoder) {
        super.encodeWithCoder(coder);
        coder.encodeInteger(numberOfQuadrants, forKey: "numberOfQuadrants")
        coder.encodeInteger(whichQuadrant, forKey: "whichQuadrant")
        
        coder.encodeObject(name, forKey: "name")
        coder.encodeInteger(xCoord, forKey: "xCoord")
        coder.encodeInteger(yCoord, forKey: "yCoord")
        coder.encodeInteger(elevation, forKey: "elevation")
        coder.encodeInteger(radius, forKey: "radius")
        coder.encodeDouble(latitude, forKey: "latitude")
        coder.encodeDouble(longitude, forKey: "longitude")
        coder.encodeInteger(algorithm, forKey: "algorithm")
    }
}

