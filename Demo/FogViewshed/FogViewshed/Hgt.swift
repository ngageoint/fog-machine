import Foundation
import MapKit

class Hgt: NSObject {
    
    var coordinate:CLLocationCoordinate2D!
    var filename:String!
    var filenameWithExtension:String!
    
    // Height files have the extension .HGT and are signed two byte integers. The
    // bytes are in Motorola "big-endian" order with the most significant byte first
    // Data voids are assigned the value -32768 and are ignored (no special processing is done)
    // SRTM3 files contain 1201 lines and 1201 samples
    lazy var elevation: [[Int]] = {
        var path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path).URLByAppendingPathComponent(self.filenameWithExtension)
        let data = NSData(contentsOfURL: url)!
        
        var elevationMatrix = [[Int]](count:Srtm3.MAX_SIZE, repeatedValue:[Int](count:Srtm3.MAX_SIZE, repeatedValue:0))
        
        let dataRange = NSRange(location: 0, length: data.length)
        var elevation = [Int16](count: data.length, repeatedValue: 0)
        data.getBytes(&elevation, range: dataRange)
        
        
        var row = 0
        var column = 0
        for cell in 0 ..< data.length {
            elevationMatrix[row][column] = Int(elevation[cell].bigEndian)
            //print(elevationMatrix[row][column])
            column += 1
            
            if column >= Srtm3.MAX_SIZE {
                column = 0
                row += 1
            }
            
            if row >= Srtm3.MAX_SIZE {
                break
            }
        }
        return elevationMatrix
    }()
    
    
    init(filename: String) {
        super.init()
        self.filename = filename
        self.filenameWithExtension = filename + Srtm.FILE_EXTENSION
        self.coordinate = parseCoordinate()
    }
    
    
    init(coordinate: CLLocationCoordinate2D) {
        super.init()
        self.coordinate = CLLocationCoordinate2DMake(floor(coordinate.latitude), floor(coordinate.longitude))
        self.filename = parseFilename()
        self.filenameWithExtension = self.filename + Srtm.FILE_EXTENSION
    }
    
    
    func getElevation() -> [[Int]] {
        return elevation
    }


    func getCoordinate() -> CLLocationCoordinate2D {
        return coordinate
    }
    
    // File names refer to the latitude and longitude of the lower left corner of
    // the tile - e.g. N37W105 has its lower left corner at 37 degrees north
    // latitude and 105 degrees west longitude
    private func parseCoordinate() -> CLLocationCoordinate2D {

        var filenameParse = filename
        
        let northSouthIndex = filenameParse.startIndex.advancedBy(1)
        let northSouth = filenameParse.substringToIndex(northSouthIndex)
        filenameParse = filenameParse.substringFromIndex(northSouthIndex)
        
        
        let latitudeIndex = filenameParse.startIndex.advancedBy(2)
        let latitudeValue = filenameParse.substringToIndex(latitudeIndex)
        filenameParse = filenameParse.substringFromIndex(latitudeIndex)
        
        let westEastIndex = filenameParse.startIndex.advancedBy(1)
        let westEast = filenameParse.substringToIndex(westEastIndex)
        filenameParse = filenameParse.substringFromIndex(westEastIndex)
        
        let longitudeValue = filenameParse
        
        var latitude:Double = Double(latitudeValue)!
        var longitude:Double = Double(longitudeValue)!
        
        if (northSouth.uppercaseString == "S") {
            latitude = latitude * -1.0
        }
        
        if (westEast.uppercaseString == "W") {
            longitude = longitude * -1.0
        }
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    // Use the coordinate and create a valid HGT filename
    func parseFilename() -> String {
        
        var filename = ""
        
        if coordinate.latitude < 0.0 {
            filename += "S"
        } else if coordinate.latitude >= 0.0 {
            filename += "N"
        }
        
        filename += String(format: "%02d", Int(abs(coordinate.latitude)))
        
        if coordinate.longitude < 0.0 {
            filename += "W"
        } else if coordinate.longitude >= 0.0 {
            filename += "E"
        }
        
        filename += String(format: "%03d", Int(abs(coordinate.longitude)))
        
        return filename
    }
    
    
    func getCenterLocation() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(coordinate.latitude + Srtm3.CENTER_OFFSET,
            coordinate.longitude + Srtm3.CENTER_OFFSET)
    }
    
    
    func hasHgtFileInDocuments() -> Bool {
        let fileManager: NSFileManager = NSFileManager.defaultManager()
        let documentsPath: String = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let url = NSURL(fileURLWithPath: documentsPath).URLByAppendingPathComponent(self.filenameWithExtension)
        
        return fileManager.fileExistsAtPath(url.path!)
    }
    
    
    func getRectangularBoundry() -> MKPolygon {
        let latitude = self.coordinate.latitude
        let longitude = self.coordinate.longitude
        var points = [
            CLLocationCoordinate2DMake(latitude, longitude),
            CLLocationCoordinate2DMake(latitude+1, longitude),
            CLLocationCoordinate2DMake(latitude+1, longitude+1),
            CLLocationCoordinate2DMake(latitude, longitude+1)
        ]
        let polygonOverlay:MKPolygon = MKPolygon(coordinates: &points, count: points.count)
        
        return polygonOverlay
    }
    
    
    override func isEqual(object: AnyObject?) -> Bool {
        if let object = object as? Hgt {
            return self.filename == object.filename
        } else {
            return false
        }
    }
    
    override var hash: Int {
        return filename.hashValue
    }
    
}