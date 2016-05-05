import Foundation
import MapKit

class HGTFile: NSObject {
    
    let path:NSURL
    // File names refer to the latitude and longitude of the lower left corner of
    // the tile - e.g. N37W105 has its lower left corner at 37 degrees north
    // latitude and 105 degrees west longitude
    var filename:String {
        return path.lastPathComponent!
    }
    
    init(path: NSURL) {
        self.path = path
        super.init()
    }

    
//    init(coordinate: CLLocationCoordinate2D) {
//        self.filename = HGTFile.coordinateToFilename(coordinate)
//        super.init()
//    }
    
    static func coordinateToFilename(coordinate:CLLocationCoordinate2D, resolution:Int) -> String {
        
        let correctedCoordinate:CLLocationCoordinate2D = CLLocationCoordinate2DMake(floor(coordinate.latitude + (1.0/Double(resolution))*0.5), floor(coordinate.longitude + (1.0/Double(resolution))*0.5))
        
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
    
    private func getLowerLeftCoordinate() -> CLLocationCoordinate2D {
        let nOrS:String = filename.substringWithRange(filename.startIndex ..< filename.startIndex.advancedBy(1))
        var lat:Double = Double(filename.substringWithRange(filename.startIndex.advancedBy(1) ..< filename.startIndex.advancedBy(3)))!

        if (nOrS.uppercaseString == "S") {
            lat = lat * -1.0
        }
        
        lat = lat - (1.0/Double(getResolution()))*0.5
        
        let wOrE:String = filename.substringWithRange(filename.startIndex.advancedBy(3) ..< filename.startIndex.advancedBy(4))
        var lon:Double = Double(filename.substringWithRange(filename.startIndex.advancedBy(4) ..< filename.startIndex.advancedBy(7)))!
        
        if (wOrE.uppercaseString == "W") {
            lon = lon * -1.0
        }
        
        lon = lon - (1.0/Double(getResolution()))*0.5
        
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    func getFileSizeInBytes() -> UInt64 {
        var fileSize : UInt64 = 0
        do {
            let attr : NSDictionary? = try NSFileManager.defaultManager().attributesOfItemAtPath(path.path!)
            if let _attr = attr {
                fileSize = _attr.fileSize();
            }
        } catch {
            print("Error: \(error)")
        }
        return fileSize
    }
    
    // this is the adjusted resoultion of the file.  files contain signed two byte integers
    func getResolution() -> Int {
        return Int(sqrt(Double(getFileSizeInBytes()/2))) - 1
    }
    
    func getBoundingBox() -> AxisOrientedBoundingBox {
        let llCoordinate:CLLocationCoordinate2D = getLowerLeftCoordinate()
        
        return AxisOrientedBoundingBox(lowerLeft: llCoordinate, upperRight: CLLocationCoordinate2DMake(llCoordinate.latitude+1.0, llCoordinate.longitude+1.0))
    }
    
    // 0,0 is lower left; 1200, 1200 is upper right
    func latLonToIndex(latLon:CLLocationCoordinate2D) -> (Int, Int) {
        let boundingBox:AxisOrientedBoundingBox = getBoundingBox()
        let resolution:Double = Double(getResolution())
        
        let llLat:Double = latLon.latitude
        let llLatGrid:Double = boundingBox.getLowerLeft().latitude
        let xIndex:Int = Int(floor((llLat - llLatGrid)*resolution))
        
        let llLon:Double = latLon.longitude
        let llLonGrid:Double = boundingBox.getLowerLeft().longitude
        let yIndex:Int = Int(floor((llLon - llLonGrid)*resolution))
        return (xIndex, yIndex)
    }
    
    override func isEqual(object: AnyObject?) -> Bool {
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