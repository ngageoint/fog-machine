import Foundation


struct Srtm {
    //SRTM = Shuttle Radar Topography Mission sampled at one arc-second
    static let SRTM1_RESOLUTION:Int = 3600
    //SRTM = Shuttle Radar Topography Mission sampled at three arc-seconds
    static let SRTM3_RESOLUTION:Int = 1200
    
    static let DATA_VOID:Int = -32768
}

enum MapType: Int {
    case Standard = 0
    case Hybrid
    case Satellite
}

public enum ViewshedAlgorithmName: String {
    case FranklinRay = "FranklinRay"
    case VanKreveld = "VanKreveld"
}