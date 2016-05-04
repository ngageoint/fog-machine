import Foundation

//SRTM = Shuttle Radar Topography Mission sampled at one arc-second
struct Srtm1 {
    static let RESOLUTION = 3600
}

//SRTM = Shuttle Radar Topography Mission sampled at three arc-seconds
struct Srtm3 {
    static let RESOLUTION = 1200
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

struct Srtm {
    static let DOWNLOAD_SERVER = "https://fogmachine.geointapps.org/version2_1/SRTM3/"
    static let ALTERNATE_DOWNLOAD_SERVER = "https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/"
    static let FILE_EXTENSION = ".hgt"
}
