import Foundation
import MapKit
import Fog

public class ViewshedWork: FogWork {
    
    static let NUMBER_OF_QUADRANTS = "numberOfQuadrants"
    static let WHICH_QUADRANT = "whichQuadrant"
    static let VIEWSHED_RESULT = "viewshedResult"
    
    static let ASSIGNED_TO = "assignedTo"
    static let SEARCH_INITIATOR = "searchInitiator"
    
    static let ALGORITHM = "algorithm"
    static let NAME = "name"
    static let XCOORD = "xCoord"
    static let YCOORD = "yCoord"
    static let ELEVATION = "elevation"
    static let RADIUS = "radius"
    static let LATITUDE = "latitude"
    static let LONGITUDE = "longitude"
    
    let numberOfQuadrants: UInt
    let whichQuadrant: UInt
    
    // Observer properties
    let name: String
    let xCoord:Int
    let yCoord:Int
    let elevation:Int
    let radius:Int
    let latitude: Double
    let longitude: Double
    let algorithm: Int

    init (numberOfQuadrants: UInt, whichQuadrant: UInt, observer: Observer) {
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
    
    public required init (serializedData: [String:NSObject]) {

        numberOfQuadrants = serializedData[ViewshedWork.NUMBER_OF_QUADRANTS] as! UInt
        whichQuadrant = serializedData[ViewshedWork.WHICH_QUADRANT] as! UInt
        name = serializedData[ViewshedWork.NAME] as! String
        xCoord = serializedData[ViewshedWork.XCOORD] as! Int
        yCoord = serializedData[ViewshedWork.YCOORD] as! Int
        elevation = serializedData[ViewshedWork.ELEVATION] as! Int
        radius = serializedData[ViewshedWork.RADIUS] as! Int
        latitude = serializedData[ViewshedWork.LATITUDE] as! Double
        longitude = serializedData[ViewshedWork.LONGITUDE] as! Double
        algorithm = serializedData[ViewshedWork.ALGORITHM] as! Int
        super.init(serializedData: serializedData)
    }
    
    public override func getDataToSerialize() -> [String:NSObject] {
        return [ViewshedWork.NUMBER_OF_QUADRANTS: numberOfQuadrants,
                ViewshedWork.WHICH_QUADRANT: whichQuadrant,
                ViewshedWork.NAME: name,
                ViewshedWork.XCOORD: xCoord,
                ViewshedWork.YCOORD: yCoord,
                ViewshedWork.ELEVATION: elevation,
                ViewshedWork.RADIUS: radius,
                ViewshedWork.LATITUDE: latitude,
                ViewshedWork.LONGITUDE: longitude,
                ViewshedWork.ALGORITHM: algorithm];
    }
}

