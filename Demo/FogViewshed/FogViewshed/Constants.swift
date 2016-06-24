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
}