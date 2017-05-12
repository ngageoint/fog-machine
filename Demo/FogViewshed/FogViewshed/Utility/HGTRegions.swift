import Foundation

class HGTRegions {

	let REGION_AFRICA = "Africa"
	let REGION_AUSTRALIA = "Australia"
	let REGION_EURASIA = "Eurasia"
	let REGION_ISLANDS = "Islands"
	let REGION_NORTH_AMERICA = "North_America"
	let REGION_SOUTH_AMERICA = "South_America"

	var filePrefixToRegion: [String: String] = [String: String]()

    init() {
        var resourceURL: URL = URL(string: Bundle.main.resourcePath!)!
        
        do {
            let hgtRegionsFile: URL = try (FileManager.default.contentsOfDirectory(at: resourceURL, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions()).filter{ $0.lastPathComponent == "HGTRegions.txt" }).first!
            
            if let aStreamReader = StreamReader(path: hgtRegionsFile.path) {
                defer {
                    aStreamReader.close()
                }
                while let line = aStreamReader.nextLine() {
                    let prefixAndRegion: [String] = line.components(separatedBy: ",")
                    filePrefixToRegion[prefixAndRegion[0]] = prefixAndRegion[1]
                }
            }
        } catch let error as NSError {
            NSLog("Error reading file: \(error.localizedDescription)")
        }

    }

    func getRegion(_ filename: String) -> String {
        let dot: Character = "."
        var region = ""
        if let idx = filename.characters.index(of: dot) {
            let pos = filename.characters.distance(from: filename.startIndex, to: idx)
            let prefix: String = filename.substring(with: filename.startIndex ..< filename.characters.index(filename.startIndex, offsetBy: pos))
            if let regionValue: String = filePrefixToRegion[prefix] {
                region = regionValue
            }
        } else {
            NSLog("Bad filename")
        }
        return region
    }
}
