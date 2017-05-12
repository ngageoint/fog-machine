import Foundation
import FogMachine
import SwiftEventBus

open class SearchTool: FMTool {

    open var searchTerm: String?

    public override init() {
        super.init()
    }

    open override func id() -> UInt32 {
        return 4149558881
    }

    open override func name() -> String {
        return "Search Tool"
    }

    open override func createWork(_ node: FMNode, nodeNumber: UInt, numberOfNodes: UInt) -> SearchWork {
        return SearchWork(peerCount: Int(numberOfNodes), peerNumber: Int(nodeNumber), searchTerm: searchTerm!)
    }
    
    fileprivate func getTextToSearch(_ peerCount: Int, peerNumber: Int) -> String {
        var resourceURL: URL = URL(string: Bundle.main.resourcePath!)!
        
        var textToSearch: String = ""
        do {
        let textToSearchFile: URL = try (FileManager.default.contentsOfDirectory(at: resourceURL, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions()).filter{ $0.lastPathComponent == "MobyDick.txt" }).first!
        
            if let aStreamReader = StreamReader(path: textToSearchFile.path) {
                defer {
                    aStreamReader.close()
                }
                while let line = aStreamReader.nextLine() {
                    textToSearch += line
                    textToSearch += "\n"
                }
            }
        } catch let error as NSError {
            searchLog("Error reading file: \(error.localizedDescription)")
        }
        
        let peerCountD: Double = Double(peerCount)
        let peerNumberD: Double = Double(peerNumber)
        
        let newline: Character = "\n"
        let numberOfCharacters: Int = textToSearch.characters.count
        var startIndex: String.CharacterView.Index
        var endIndex: String.CharacterView.Index
        if(peerNumber == 0) {
            startIndex = textToSearch.startIndex
        } else {
            startIndex = textToSearch.characters.index(textToSearch.startIndex, offsetBy: Int(floor((peerNumberD / peerCountD) * Double(numberOfCharacters))))
            while(startIndex > textToSearch.startIndex && (textToSearch[startIndex] != newline)) {
                startIndex = textToSearch.index(startIndex, offsetBy: -1)
            }
        }
        
        if(peerNumber + 1 == peerCount) {
            endIndex = textToSearch.endIndex
        } else {
            endIndex = textToSearch.characters.index(textToSearch.startIndex, offsetBy: Int(floor(((peerNumberD + 1) / peerCountD) * Double(numberOfCharacters))))
            while(endIndex > textToSearch.startIndex && (textToSearch[endIndex] != newline)) {
                endIndex = textToSearch.index(endIndex, offsetBy: -1)
            }
        }
        
        searchLog("startIndex \(startIndex), endIndex \(endIndex)")
        
        return textToSearch[startIndex..<endIndex]
    }

    // used for KMP, Build pi function of prefixes
    fileprivate func build_pi(_ str: String) -> [Int] {
        let n = str.characters.count
        var pi = Array(repeating: 0, count: n + 1)
        var k:Int = -1
        pi[0] = -1
        
        for i in 0..<n {
            while (k >= 0 && (str[str.characters.index(str.startIndex, offsetBy: k)] != str[str.characters.index(str.startIndex, offsetBy: i)])) {
                k = pi[k]
            }
            k+=1
            pi[i + 1] = k
        }
        
        return pi
    }
    
    // Knuth-Morris Pratt algorithm
    fileprivate func KMP(_ text: String, pattern: String) -> [Int] {
        
        // Convert to Character array to index in O(1)
        var patt = Array(pattern.characters)
        var S = Array(text.characters)
        
        var matches = [Int]()
        let n = text.characters.count
        
        let m = pattern.characters.count
        var k = 0
        var pi = build_pi(pattern)
        
        for i in 0..<n {
            while (k >= 0 && (k == m || patt[k] != S[i])) {
                k = pi[k]
            }
            k += 1
            if (k == m) {
                matches.append(i - m + 1)
            }
        }
        
        return matches
    }
    
    open override func processWork(_ node: FMNode, fromNode: FMNode, work: FMWork) -> SearchResult {
        let searchWork:SearchWork = work as! SearchWork
        let textFoundAt:[Int] = KMP(getTextToSearch(searchWork.peerCount, peerNumber: searchWork.peerNumber), pattern: searchWork.searchTerm)
        
        return SearchResult(numberOfOccurrences: textFoundAt.count)
    }
    
    open override func mergeResults(_ node: FMNode, nodeToResult: [FMNode: FMResult]) -> Void {
        var totalNumberOfOccurrences: Int = 0
        for (n, result) in nodeToResult {
            let searchResult = result as! SearchResult
            NSLog("Received result from node " + n.description)
            totalNumberOfOccurrences += searchResult.numberOfOccurrences
        }
                searchLog("The word '\(self.searchTerm!)' was found in \(totalNumberOfOccurrences) times in the text.\n")
        SwiftEventBus.post(SearchEventBusEvents.searchComplete)
    }

    open override func onPeerConnect(_ myNode: FMNode, connectedNode: FMNode) {
        SwiftEventBus.post(FogMachineEventBusEvents.onPeerConnect)
    }

    open override func onPeerDisconnect(_ myNode: FMNode, disconnectedNode: FMNode) {
        SwiftEventBus.post(FogMachineEventBusEvents.onPeerDisconnect)
    }

    open func searchLog(_ format: String) {
        NSLog(format)
        self.onLog(format)
    }

    open override func onLog(_ format: String) {
        SwiftEventBus.post(SearchEventBusEvents.onLog, sender: format as AnyObject)
    }
}
