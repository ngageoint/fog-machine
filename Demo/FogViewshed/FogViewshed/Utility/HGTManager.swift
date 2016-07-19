import Foundation
import MapKit
import SwiftEventBus

public class HGTManager {
    static func isFileInDocuments(fileName: String) -> Bool {
        let fileManager: NSFileManager = NSFileManager.defaultManager()
        let documentsPath: String = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let url = NSURL(fileURLWithPath: documentsPath).URLByAppendingPathComponent(fileName)
        return fileManager.fileExistsAtPath(url.path!)
    }
    
    static func copyHGTFilesToDocumentsDir() {
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
        } catch let error as NSError  {
            NSLog("Problem copying files: \(error.localizedDescription)")
        }
    }
    
    static private func getLocalHGTFileMap() -> [String:HGTFile] {
        var hgtFiles:[String:HGTFile] = [String:HGTFile]()
        let documentsUrl:NSURL =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        do {
            let hgtPaths:[NSURL] = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(documentsUrl, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions()).filter{ $0.pathExtension == "hgt" }

            for hgtpath in hgtPaths {
                hgtFiles[hgtpath.lastPathComponent!] = HGTFile(path: hgtpath)
                
            }
        } catch let error as NSError {
            NSLog("Error reading file: \(error.localizedDescription)")
        }

        return hgtFiles
    }
    
    static func getLocalHGTFiles() -> [HGTFile] {
        var files:[HGTFile] = Array(getLocalHGTFileMap().values)
        
        files.sortInPlace { (obj1, obj2) -> Bool in
            return obj1.filename < obj2.filename
        }
        return files
    }
    
    static func getLocalHGTFileByName(filename:String) -> HGTFile? {
        return getLocalHGTFileMap()[filename]
    }
    
    static func deleteFile(hgtFile: HGTFile) {
        if NSFileManager.defaultManager().fileExistsAtPath(hgtFile.path.relativePath!) {
            do {
                try NSFileManager.defaultManager().removeItemAtPath(hgtFile.path.relativePath!)
            } catch let error as NSError  {
                print("Error occurred during file delete : \(error.localizedDescription)")
            }
        }
    }

    /**
     
     Converts a (lat,lon) to an index in the grid.  Used by several classes to map data.
     
     In the indexed returned, (0,0) is lower left; (resolution, resolution) is upper right
 
    */
    static func latLonToIndex(latLon:CLLocationCoordinate2D, boundingBox:AxisOrientedBoundingBox, resolution:Int) -> (Int, Int) {
        let resolutionD:Double = Double(resolution)
        
        let llLat:Double = latLon.latitude
        let llLatGrid:Double = boundingBox.getLowerLeft().latitude
        let latDiff:Double = llLat - llLatGrid
        let latDiffGrid:Double = boundingBox.getUpperRight().latitude - boundingBox.getLowerLeft().latitude
        var latIndexMax:Int = smartFloorI(latDiffGrid*resolutionD)
        if(latDiff == latDiffGrid) {
            latIndexMax -= 1
        }
        let yIndex:Int = max(min(smartFloorI(latDiff*resolutionD), latIndexMax), 0)
        
        let llLon:Double = latLon.longitude
        let llLonGrid:Double = boundingBox.getLowerLeft().longitude
        let lonDiff:Double = llLon - llLonGrid
        let lonDiffGrid:Double = boundingBox.getUpperRight().longitude - boundingBox.getLowerLeft().longitude
        var lonIndexMax:Int = smartFloorI(lonDiffGrid*resolutionD)
        if(lonDiff == lonDiffGrid) {
            lonIndexMax -= 1
        }
        let xIndex:Int = max(min(smartFloorI(lonDiff*resolutionD), lonIndexMax), 0)
        
        return (xIndex, yIndex)
    }
    
    static private let NUMERICAL_PRECISION:Double = 8
    
    /**
     
     Finds the floor of the number, but will account for the numerical imprecision in doubles, like 37.999999999345 or -102.6666666666234
 
    */
    static private func smartFloorI(d:Double) -> Int {
        return Int(smartFloorD(d))
    }
    
    static private func smartFloorD(d:Double) -> Double {
        let precision:Double = pow(10, NUMERICAL_PRECISION)
        return floor(Double(round(precision*d)/precision))
    }
    
    /**
     
     See smartFloorI
     
     */
    static private func smartCeilI(d:Double) -> Int {
        return Int(smartCeilD(d))
    }
    
    static private func smartCeilD(d:Double) -> Double {
        let precision:Double = pow(10, NUMERICAL_PRECISION)
        return ceil(Double(round(precision*d)/precision))
    }
    
    /**
     
     This is the main method for reading and coalescing the elevation data.  There are several important steps here:
     
     1) Expand the bounding box to the gridded space formed by the srtm files at a certain resolution.  This is convenient and imporatnt for a few reasons.  First, it defines the exact area the datum at a certain resolution exists at.  Again, this is the exact map extent in which the AREA data exists at.  Second, it makes the algerbra and data processing a little more straightforward.  The bounding box is found using linear interpolation in the lat lon space.  Please note that we are note tied to any projection at this point.  Would it be better to use a smarter interpolation at account for earth curvature as in WGS84?  I don't know.
     
     2) Find all of the local hgt files that are covered by the space formed in step 1.  This is fairly straight forward.
     
     3) Determine the extent of the final elevation matrix.  Some indexing
     
     4) For each file in step 2, find the intersection between it and the bounding box in step 1.
     
     5) Using the intersection in step 4, read in the appropriate elevation data from the corresponding file.  Parse the data, and write it into the final elevation matrix.
     
     FIXME: Crossing the 180th meridian?  This method will fail in at least 10 ways...  someone should fix that...
     
     NOTE:
     For the purpose of this application, we will ignore the first row (top row) and the last column (right column)
     in the hgt files.  This will be done to avoid dealing with the overlap that extists across the hgt files.
     Doing this will provide a perfect tiling.
     
     STRM Information:
     
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
     
     */
    static func getElevationGrid(axisOrientedBoundingBox:AxisOrientedBoundingBox, resolution resolutioni:Int) -> DataGrid {
        
        let resolutiond:Double = Double(resolutioni)
        
        // this is the size of a cell in degrees
        let cellSizeInDegrees:Double = 1.0/resolutiond
        let halfCellSizeInDegrees:Double = cellSizeInDegrees/2.0
        
        // expand the bounds of the bounding box to snap to the srtm grid size
        
        // lower left
        let llLatCell:Double = axisOrientedBoundingBox.getLowerLeft().latitude
        let llLatGrid:Double = smartFloorD(llLatCell) - halfCellSizeInDegrees
        let llLatCellGrided:Double = llLatGrid + (smartFloorD((llLatCell - llLatGrid)*resolutiond)*cellSizeInDegrees)
        
        let llLonCell:Double = axisOrientedBoundingBox.getLowerLeft().longitude
        let llLonGrid:Double = smartFloorD(llLonCell) - halfCellSizeInDegrees
        let llLonCellGrided:Double = llLonGrid + (smartFloorD((llLonCell - llLonGrid)*resolutiond)*cellSizeInDegrees)
        
        // upper right
        let urLatCell:Double = axisOrientedBoundingBox.getUpperRight().latitude
        let urLatGrid:Double = smartFloorD(urLatCell) - halfCellSizeInDegrees
        let urLatCellGrided:Double = urLatGrid + (smartCeilD((urLatCell - urLatGrid)*resolutiond)*cellSizeInDegrees)

        let urLonCell:Double = axisOrientedBoundingBox.getUpperRight().longitude
        let urLonGrid:Double = smartFloorD(urLonCell) - halfCellSizeInDegrees
        let urLonCellGrided:Double = urLonGrid + (smartCeilD((urLonCell - urLonGrid)*resolutiond)*cellSizeInDegrees)
        
        // this is the bounding box, expanded and snapped to the grid
        let griddedAxisOrientedBoundingBox:AxisOrientedBoundingBox = AxisOrientedBoundingBox(lowerLeft: CLLocationCoordinate2DMake(llLatCellGrided, llLonCellGrided), upperRight: CLLocationCoordinate2DMake(urLatCellGrided, urLonCellGrided))
        
        // get hgt files of interest
        var hgtFilesOfInterest:[HGTFile] = [HGTFile]()
        
        // looping vars
        
        var iLat:Double = llLatGrid
        var iLon:Double = llLonGrid

        // get all the files that are covered by this bounding box
        while(iLat <= urLatGrid) {
            iLon = llLonGrid
            while(iLon <= urLonGrid) {
                let hgtFile:HGTFile? = HGTManager.getLocalHGTFileByName(HGTFile.coordinateToFilename(CLLocationCoordinate2DMake(iLat, iLon), resolution: resolutioni))
                if(hgtFile != nil) {
                    hgtFilesOfInterest.append(hgtFile!)
                    NSLog("File of interest: " + hgtFile!.filename)
                }
                iLon += 1.0
            }
            iLat += 1.0
        }
        
        NSLog("griddedAxisOrientedBoundingBox: " + griddedAxisOrientedBoundingBox.description)
        
        let elevationDataURIndex:(Int, Int) = HGTManager.latLonToIndex(griddedAxisOrientedBoundingBox.getUpperRight(), boundingBox: griddedAxisOrientedBoundingBox, resolution: resolutioni)
        let elevationDataLLIndex:(Int, Int) = HGTManager.latLonToIndex(griddedAxisOrientedBoundingBox.getLowerLeft(), boundingBox: griddedAxisOrientedBoundingBox, resolution: resolutioni)
        
        let elevationDataWidth:Int = elevationDataURIndex.0 - elevationDataLLIndex.0 + 1
        let elevationDataHeight:Int = elevationDataURIndex.1 - elevationDataLLIndex.1 + 1
        
//        NSLog("elevationDataHeight \(elevationDataHeight)")
//        NSLog("elevationDataWidth \(elevationDataWidth)")
        
        // this is the data structure that will contain the elevation data
        var elevationData:[[Int]] = [[Int]](count:elevationDataHeight, repeatedValue:[Int](count:elevationDataWidth, repeatedValue:Srtm.NO_DATA))
        
        // read sections of each file and fill in the martix as needed
        for hgtFileOfInterest:HGTFile in hgtFilesOfInterest {
            
            let hgtFileBoundingBox:AxisOrientedBoundingBox = hgtFileOfInterest.getBoundingBox()
            
            // make sure this hgtfile intersects the bounding box
            if(hgtFileBoundingBox.intersectionExists(griddedAxisOrientedBoundingBox)) {
                // find the intersection
                let hgtAreaOfInterest:AxisOrientedBoundingBox = hgtFileBoundingBox.intersection(griddedAxisOrientedBoundingBox)
                
                NSLog("hgtAreaOfInterest: " + hgtAreaOfInterest.description)
                
                // we need to read data from the upper left of the intersection to the lower right of the intersection
                var upperLeftIndex:(Int, Int) = hgtFileOfInterest.latLonToIndex(hgtAreaOfInterest.getUpperLeft())
                var lowerRightIndex:(Int, Int) = hgtFileOfInterest.latLonToIndex(hgtAreaOfInterest.getLowerRight())
                
                // bound the indicies to the boundary of the gridded space
                upperLeftIndex.1 = min(upperLeftIndex.1, lowerRightIndex.1 + elevationDataHeight - 1)
                lowerRightIndex.0 = min(lowerRightIndex.0, upperLeftIndex.0 + elevationDataWidth - 1)
                
                // the files are enumerated from top to bottom, left to right, so flip the yIndex
                upperLeftIndex.1 = hgtFileOfInterest.getResolution() - 1 - upperLeftIndex.1
                lowerRightIndex.1 = hgtFileOfInterest.getResolution() - 1 - lowerRightIndex.1
//                NSLog("upperLeftIndex \(upperLeftIndex.0) \(upperLeftIndex.1)")
//                NSLog("lowerRightIndex \(lowerRightIndex.0) \(lowerRightIndex.1)")
                
                let hgtAreaOfInterestHeight:Int = lowerRightIndex.1 - upperLeftIndex.1 + 1
                let hgtAreaOfInterestWidth:Int = lowerRightIndex.0 - upperLeftIndex.0 + 1
//                NSLog("hgtAreaOfInterestHeight \(hgtAreaOfInterestHeight)")
//                NSLog("hgtAreaOfInterestWidth \(hgtAreaOfInterestWidth)")
                
                // data row length, 2 bytes for every index
                let dataRowLengthInBytes:Int = 2*(hgtAreaOfInterestWidth)
//                NSLog("dataRowLengthInBytes \(dataRowLengthInBytes)")
                
                // always skip the first row of data + plus the extra cell in the last column that we don't care about
                var numberOfBytesToStartReadingAt:UInt64 = UInt64((hgtFileOfInterest.getResolution() + 1) * 2)
//                NSLog("numberOfBytesToStartReadingAt \(numberOfBytesToStartReadingAt)")
                
                // then skip the data until the exact of offset we want to read at
                // account for each row and the last column, AND the offset in the current row
                numberOfBytesToStartReadingAt = numberOfBytesToStartReadingAt + UInt64(((upperLeftIndex.1 * (hgtFileOfInterest.getResolution() + 1)) + upperLeftIndex.0)*2)
//                NSLog("numberOfBytesToStartReadingAt \(numberOfBytesToStartReadingAt)")
                
                // the last bytes are the start byte plus the number of columns minus one * the size of each row, plus the length of the last row
                let numberOfBytesUntilLastByteToRead:UInt64 = numberOfBytesToStartReadingAt + UInt64(2*((hgtAreaOfInterestHeight - 1)*(hgtFileOfInterest.getResolution() + 1)) + dataRowLengthInBytes)
//                NSLog("numberOfBytesUntilLastByteToRead \(numberOfBytesUntilLastByteToRead)")
                
                do {
                    let handle:NSFileHandle = try NSFileHandle(forReadingFromURL: hgtFileOfInterest.path)
                    
                    // TODO : TBD, it may be faster to read an entire block of data, and then parse the information out of the file.
                    
                    var rowNumber:Int = 0
                    let elevationDataIndex:(Int, Int) = HGTManager.latLonToIndex(hgtAreaOfInterest.getLowerLeft(), boundingBox: griddedAxisOrientedBoundingBox, resolution: resolutioni)
                    
//                    NSLog("elevationDataIndex.0 \(elevationDataIndex.0)")
//                    NSLog("elevationDataIndex.1 \(elevationDataIndex.1)")
                    
                    // while there are more rows to read
                    while(numberOfBytesToStartReadingAt <= numberOfBytesUntilLastByteToRead) {
                        handle.seekToFileOffset(numberOfBytesToStartReadingAt)
                        let data:NSData = handle.readDataOfLength(dataRowLengthInBytes)
                        var oneRowOfElevation = [Int16](count: data.length, repeatedValue: Int16(Srtm.NO_DATA))
                        let dataRange = NSRange(location: 0, length: data.length)
                        // read the row into the temp structure
                        data.getBytes(&oneRowOfElevation, range: dataRange)
                        
                        // the byte order is backwards, so flip it.  Don't think there's a faster way to do this
                        for cell in 0 ..< (data.length/2) {
                            // find the index where this row should be indexed into the large elevationData structure
                            let column:Int = elevationDataIndex.1 + hgtAreaOfInterestHeight - 1 - rowNumber;
                            let row:Int = elevationDataIndex.0 + cell
                            if(row < elevationDataWidth && row >= 0 && column < elevationDataHeight && column >= 0) {
                                elevationData[column][row] = Int(oneRowOfElevation[cell].bigEndian)
                            }
                        }
                        
                        // seek to the next row
                        numberOfBytesToStartReadingAt = numberOfBytesToStartReadingAt + UInt64((hgtFileOfInterest.getResolution() + 1)*2)
                        rowNumber += 1
                    }
                } catch let error as NSError {
                    NSLog("Error reading HGT file: \(error.localizedDescription)")
                }
            }
        }
        
        return DataGrid(data: elevationData, boundingBoxAreaExtent: griddedAxisOrientedBoundingBox, resolution: resolutioni)
    }
    
}