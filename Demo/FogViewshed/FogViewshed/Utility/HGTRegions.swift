import Foundation

class HGTRegions {

	let REGION_AFRICA = "Africa"
	let REGION_AUSTRALIA = "Australia"
	let REGION_EURASIA = "Eurasia"
	let REGION_ISLANDS = "Islands"
	let REGION_NORTH_AMERICA = "North_America"
	let REGION_SOUTH_AMERICA = "South_America"

	var filePrefixToRegion:[String:String] = [String:String]()

    init() {
        var resourceURL:NSURL = NSURL(string: NSBundle.mainBundle().resourcePath!)!
        
        do {
            let hgtRegionsFile:NSURL = try (NSFileManager.defaultManager().contentsOfDirectoryAtURL(resourceURL, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions()).filter{ $0.lastPathComponent == "HGTRegions.txt" }).first!
            
            if let aStreamReader = StreamReader(path: hgtRegionsFile.path!) {
                defer {
                    aStreamReader.close()
                }
                while let line = aStreamReader.nextLine() {
                    let prefixAndRegion:[String] = line.componentsSeparatedByString(",")
                    filePrefixToRegion[prefixAndRegion[0]] = prefixAndRegion[1]
                }
            }
        } catch let error as NSError {
            NSLog("Error reading file: \(error.localizedDescription)")
        }

    }

    func getRegion(filename:String) -> String {
        let dot:Character = "."
        if let idx = filename.characters.indexOf(dot) {
            let pos = filename.startIndex.distanceTo(idx)
            let prefix:String = filename.substringWithRange(filename.startIndex ..< filename.startIndex.advancedBy(pos))
            if let region:String = filePrefixToRegion[prefix] {
                return region
            }
        } else {
            NSLog("Bad filename")
        }
        return ""
    }
}
