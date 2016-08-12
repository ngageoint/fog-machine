import Foundation


struct Srtm {
    //SRTM = Shuttle Radar Topography Mission sampled at one arc-second
    static let SRTM1_RESOLUTION:Int = 3600
    //SRTM = Shuttle Radar Topography Mission sampled at three arc-seconds
    static let SRTM3_RESOLUTION:Int = 1200
    
    static let DATA_VOID:Int = -32768
    static let NO_DATA:Int = DATA_VOID + 1
}

struct Viewshed {
    static let NO_DATA:Int = Srtm.NO_DATA
    static let VISIBLE:Int = 1
    static let NOT_VISIBLE:Int = 0
    static let OBSERVER:Int = 2
}

enum MapType: Int {
    case Standard = 0
    case Hybrid
    case Satellite
}

public enum ViewshedAlgorithmName: String {
    case FranklinRay = "Franklin and Ray's"
    case VanKreveld = "Van Kreveld"
}

struct ViewshedEventBusEvents {
    static let viewshedComplete:String = "viewshedComplete"
    static let onLog:String = "onLog"
    static let drawGridOverlay:String = "drawGridOverlay"
    static let addObserverPin:String = "addObserverPin"
    static let viewshed3d: String = "viewshed3d"
}

struct Elevation {
    // Reference: https://en.wikipedia.org/wiki/Extreme_points_of_Earth
    // Tallest point from sea level is <9000 meters (Mount Everest at 8,848m)
    static let MAX_BOUND = 9000
    // Lowest point on dry land >-450 meters (The shore of the Dead Sea at -418m)
    static let MIN_BOUND = -450
    
}