import Foundation
import MapKit

public class HGTManager {
    static func isFileInDocuments(fileName: String) -> Bool {
        let fileManager: NSFileManager = NSFileManager.defaultManager()
        let documentsPath: String = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let url = NSURL(fileURLWithPath: documentsPath).URLByAppendingPathComponent(fileName)
        return fileManager.fileExistsAtPath(url.path!)
    }
    
    static func copyHGTFilesToDocumentsDir() {
        let prefs = NSUserDefaults.standardUserDefaults()
        
        // copy the data over to documents dir, if it's never been done.
        if !prefs.boolForKey("hasCopyData") {
            
            let fromPath:String = NSBundle.mainBundle().resourcePath!
            let toPath: String = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
            
            do {
                let fileManager = NSFileManager.defaultManager()
                let resourceFiles:[String] = try fileManager.contentsOfDirectoryAtPath(fromPath)
                
                for file in resourceFiles {
                    if file.hasSuffix(".hgt") {
                        let fromFilePath = fromPath + "/" + file
                        let toFilePath = toPath + "/" + file
                        if (fileManager.fileExistsAtPath(toFilePath) == false) {
                            try fileManager.copyItemAtPath(fromFilePath, toPath: toFilePath)
                            NSLog("Copying " + file + " to documents directory.")
                        }
                    }
                }
                prefs.setValue(true, forKey: "hasCopyData")
            } catch let error as NSError  {
                NSLog("Problem copying files: \(error.localizedDescription)")
            }
        }
    }
    
    static func getLocalHGTFiles() -> [HGTFile] {
        var hgtFiles:[HGTFile] = [HGTFile]()
        let documentsUrl:NSURL =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        do {
            let hgtPaths:[NSURL] = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(documentsUrl, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions()).filter{ $0.pathExtension == "hgt" }

            for hgtpath in hgtPaths {
                hgtFiles.append(HGTFile(path: hgtpath))
                
            }
        } catch let error as NSError {
            NSLog("Error displaying HGT file: \(error.localizedDescription)")
        }

        return hgtFiles
    }
    
    

    /**
     
     see https://dds.cr.usgs.gov/srtm/version2_1/Documentation/Quickstart.pdf for more information
     
     SRTM data are distributed in two levels: SRTM1 (for the U.S. and its territories
     and possessions) with data sampled at one arc-second intervals in latitude and
     longitude, and SRTM3 (for the world) sampled at three arc-seconds. Three
     arc-second data are generated by three by three averaging of the one
     arc-second samples.
     
     Data are divided into one by one degree latitude and longitude tiles in
     "geographic" projection, which is to say a raster presentation with equal
     intervals of latitude and longitude in no projection at all but easy to manipulate
     and mosaic.
     
     File names refer to the latitude and longitude of the lower left corner of
     the tile - e.g. N37W105 has its lower left corner at 37 degrees north
     latitude and 105 degrees west longitude. To be more exact, these
     coordinates refer to the geometric center of the lower left pixel, which in
     the case of SRTM3 data will be about 90 meters in extent.
     
     Height files have the extension .HGT and are signed two byte integers. The
     bytes are in Motorola "big-endian" order with the most significant byte first,
     directly readable by systems such as Sun SPARC, Silicon Graphics and Macintosh
     computers using Power PC processors. DEC Alpha, most PCs and Macintosh
     computers built after 2006 use Intel ("little-endian") order so some byte-swapping
     may be necessary. Heights are in meters referenced to the WGS84/EGM96 geoid.
     Data voids are assigned the value -32768.
     
     SRTM3 files contain 1201 lines and 1201 samples. The rows at the north
     and south edges as well as the columns at the east and west edges of each
     cell overlap and are identical to the edge rows and columns in the adjacent
     cell. SRTM1 files contain 3601 lines and 3601 samples, with similar overlap.

     
     
     
     NOTE:
     For the purpose of this application, we will ignore the first row (top row) and the last column (right column)
     in the hgt files.  This will be done to avoid dealing with the overlap that extists across the hgt files.  
     Doing this will provide a perfect tiling.
     
     */
    static func getElevationGrid(axisOrientedBoundingBox:AxisOrientedBoundingBox) -> ElevationDataGrid {
        
        // TODO: pass this in
        let resolutioni:Int = Srtm3.RESOLUTION
        let resolutiond:Double = Double(resolutioni)
        
        // this is the size of a cell in degrees
        let cellSizeInDegrees:Double = 1.0/resolutiond
        
        // expand the bounds of the bounding box to snap to the srtm grid size
        
        var signCorrection:Double = 1.0
        // lower left
        let llLatCell:Double = axisOrientedBoundingBox.getLowerLeft().latitude
        let llLatGrid:Double = floor(llLatCell) - (cellSizeInDegrees/2.0)
        if(llLatGrid < 0) {
            signCorrection = -1.0
        } else {
            signCorrection = 1.0
        }
        let llLatCellGrided:Double = llLatGrid + (floor((llLatCell - llLatGrid)*resolutiond)*cellSizeInDegrees)
        
        let llLonCell:Double = axisOrientedBoundingBox.getLowerLeft().longitude
        let llLonGrid:Double = floor(llLonCell) - (cellSizeInDegrees/2.0)
        if(llLonGrid < 0) {
            signCorrection = -1.0
        } else {
            signCorrection = 1.0
        }
        let llLonCellGrided:Double = llLonGrid + (floor((llLonCell - llLonGrid)*resolutiond)*cellSizeInDegrees)
        
        // upper right
        let urLatCell:Double = axisOrientedBoundingBox.getUpperRight().latitude
        let urLatGrid:Double = floor(urLatCell) - (cellSizeInDegrees/2.0)
        if(urLatGrid < 0) {
            signCorrection = -1.0
        } else {
            signCorrection = 1.0
        }
        let urLatCellGrided:Double = urLatGrid + (ceil((urLatCell - urLatGrid)*resolutiond)*cellSizeInDegrees)

        let urLonCell:Double = axisOrientedBoundingBox.getUpperRight().longitude
        let urLonGrid:Double = floor(urLonCell) - (cellSizeInDegrees/2.0)
        if(urLonGrid < 0) {
            signCorrection = -1.0
        } else {
            signCorrection = 1.0
        }
        let urLonCellGrided:Double = urLonGrid + (ceil((urLonCell - urLonGrid)*resolutiond)*cellSizeInDegrees)
        
        // this is the bounding box, snapped to the grid
        let griddedAxisOrientedBoundingBox:AxisOrientedBoundingBox = AxisOrientedBoundingBox(lowerLeft: CLLocationCoordinate2DMake(llLatCellGrided, llLonCellGrided), upperRight: CLLocationCoordinate2DMake(urLatCellGrided, urLonCellGrided))
        
        // get hgt files of interest
        var hgtFilesOfInterest:[HGTFile] = [HGTFile]()
        
        let filename:String = HGTFile.coordinateToFilename(griddedAxisOrientedBoundingBox.getLowerLeft());
        
        for file in HGTManager.getLocalHGTFiles() {
            if(file.filename == filename) {
                hgtFilesOfInterest.append(file)
            }
        }
        
        
        // get the interestion between the hgtfile
        if(hgtFilesOfInterest[0].getBoundingBox().intersectionExists(griddedAxisOrientedBoundingBox)) {
            let hgtAreaOfIntrest:AxisOrientedBoundingBox = hgtFilesOfInterest[0].getBoundingBox().intersection(griddedAxisOrientedBoundingBox)
            
            
            
        }
        
    
//        var elevation = [[Int]](count:Srtm3.MAX_SIZE, repeatedValue:[Int](count:Srtm3.MAX_SIZE, repeatedValue:0))
//    
//        var path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
//        let url = NSURL(fileURLWithPath: path).URLByAppendingPathComponent(self.filenameWithExtension)
//        let data = NSData(contentsOfURL: url)!
//        
//
//        
//        let dataRange = NSRange(location: 0, length: data.length)
//        var elevation = [Int16](count: data.length, repeatedValue: 0)
//        data.getBytes(&elevation, range: dataRange)
//        
//        
//        var row = 0
//        var column = 0
//        for cell in 0 ..< data.length {
//            elevationMatrix[row][column] = Int(elevation[cell].bigEndian)
//            //print(elevationMatrix[row][column])
//            column += 1
//            
//            if column >= Srtm3.MAX_SIZE {
//                column = 0
//                row += 1
//            }
//            
//            if row >= Srtm3.MAX_SIZE {
//                break
//            }
//        }

        
        return ElevationDataGrid(elevationData: [[Int]](),boundingBoxAreaExtent: griddedAxisOrientedBoundingBox, resolution: resolutioni)
    }
}