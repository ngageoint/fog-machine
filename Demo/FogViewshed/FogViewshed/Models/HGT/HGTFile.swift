import Foundation
import MapKit


/**
 
 Has information concerning an HGT file on the filesystem
 
 */
class HGTFile: NSObject {
    
    let path: URL
    // File names refer to the latitude and longitude of the lower left corner of
    // the tile - e.g. N37W105 has its lower left corner at 37 degrees north
    // latitude and 105 degrees west longitude
    var filename: String {
        return path.lastPathComponent
    }
    
    init(path: URL) {
        self.path = path
        super.init()
    }
    
    static func coordinateToFilename(_ coordinate: CLLocationCoordinate2D, resolution: Int) -> String {
        // adjust the boundary.  Don't run this near the poles...
        let correctedCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(floor(coordinate.latitude + (1.0 / Double(resolution)) * 0.5), floor(coordinate.longitude + (1.0 / Double(resolution)) * 0.5))
        
        var filename = ""
        if (correctedCoordinate.latitude < 0.0) {
            filename += "S"
        } else {
            filename += "N"
        }
        filename += String(format: "%02d", Int(abs(correctedCoordinate.latitude)))
        
        if (correctedCoordinate.longitude < 0.0) {
            filename += "W"
        } else {
            filename += "E"
        }
        filename += String(format: "%03d", Int(abs(correctedCoordinate.longitude)))
        filename += ".hgt"
        
        return filename
    }
    
    func getFileSizeInBytes() -> UInt64 {
        var fileSize: UInt64 = 0
        do {
            let attr: NSDictionary? = try FileManager.default.attributesOfItem(atPath: path.path) as NSDictionary
            if let _attr = attr {
                fileSize = _attr.fileSize()
            }
        } catch {
            print("Error: \(error)")
        }
        return fileSize
    }
    
    // Get adjusted resolution of the file.  Files contain signed two byte integers
    func getResolution() -> Int {
        return Int(sqrt(Double(getFileSizeInBytes() / 2))) - 1
    }
    
    fileprivate func getLowerLeftCoordinate() -> CLLocationCoordinate2D {
        let nOrS: String = filename.substring(with: filename.startIndex ..< filename.characters.index(filename.startIndex, offsetBy: 1))
        var lat: Double = Double(filename.substring(with: filename.characters.index(filename.startIndex, offsetBy: 1) ..< filename.characters.index(filename.startIndex, offsetBy: 3)))!
        
        if (nOrS.uppercased() == "S") {
            lat *= -1.0
        }
        
        lat = lat - (1.0 / Double(getResolution())) * 0.5
        
        let wOrE:String = filename.substring(with: filename.characters.index(filename.startIndex, offsetBy: 3) ..< filename.characters.index(filename.startIndex, offsetBy: 4))
        var lon:Double = Double(filename.substring(with: filename.characters.index(filename.startIndex, offsetBy: 4) ..< filename.characters.index(filename.startIndex, offsetBy: 7)))!
        
        if (wOrE.uppercased() == "W") {
            lon *= -1.0
        }
        
        lon = lon - (1.0 / Double(getResolution())) * 0.5
        
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    func getBoundingBox() -> AxisOrientedBoundingBox {
        let llCoordinate: CLLocationCoordinate2D = getLowerLeftCoordinate()
        
        return AxisOrientedBoundingBox(lowerLeft: llCoordinate, upperRight: CLLocationCoordinate2DMake(llCoordinate.latitude + 1.0, llCoordinate.longitude + 1.0))
    }
    
    func latLonToIndex(_ latLon: CLLocationCoordinate2D) -> (Int, Int) {
        return HGTManager.latLonToIndex(latLon, boundingBox: getBoundingBox(), resolution: getResolution())
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? HGTFile {
            return self.filename == object.filename
        } else {
            return false
        }
    }
    
    override var hash: Int {
        return filename.hashValue
    }
}
