import Foundation
import FogMachine
import SwiftEventBus

public class SearchTool : FMTool {

    public var searchTerm:String?

    public override init() {
        super.init()
    }

    public override func id() -> UInt32 {
        return 4149558881
    }

    public override func name() -> String {
        return "Search Tool"
    }

    public override func createWork(node:FMNode, nodeNumber:UInt, numberOfNodes:UInt) -> SearchWork {
        return SearchWork(peerCount: Int(numberOfNodes), peerNumber: Int(nodeNumber), searchTerm: searchTerm!)
    }
    
    private func getTextToSearch(peerCount:Int, peerNumber:Int) -> String {
        var resourceURL:NSURL = NSURL(string: NSBundle.mainBundle().resourcePath!)!
        
        var textToSearch:String = ""
        do {
        let textToSearchFile:NSURL = try (NSFileManager.defaultManager().contentsOfDirectoryAtURL(resourceURL, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions()).filter{ $0.lastPathComponent == "MobyDick.txt" }).first!
        
            if let aStreamReader = StreamReader(path: textToSearchFile.path!) {
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
        
        let peerCountD:Double = Double(peerCount)
        let peerNumberD:Double = Double(peerNumber)
        
        let newline:Character = "\n"
        let numberOfCharacters:Int = textToSearch.characters.count
        var startIndex:String.CharacterView.Index
        var endIndex:String.CharacterView.Index
        if(peerNumber == 0) {
            startIndex = textToSearch.startIndex
        } else {
            startIndex = textToSearch.startIndex.advancedBy(Int(floor((peerNumberD/peerCountD)*Double(numberOfCharacters))))
            while(startIndex > textToSearch.startIndex && (textToSearch[startIndex] != newline)) {
                startIndex = startIndex.advancedBy(-1)
            }
        }
        
        if(peerNumber + 1 == peerCount) {
            endIndex = textToSearch.endIndex
        } else {
            endIndex = textToSearch.startIndex.advancedBy(Int(floor(((peerNumberD + 1)/peerCountD)*Double(numberOfCharacters))))
            while(endIndex > textToSearch.startIndex && (textToSearch[endIndex] != newline)) {
                endIndex = endIndex.advancedBy(-1)
            }
        }
        
        searchLog("startIndex \(startIndex), endIndex \(endIndex)")
        
        return textToSearch[startIndex..<endIndex]
    }

    // used for KMP, Build pi function of prefixes
    private func build_pi(str: String) -> [Int] {
        let n = str.characters.count
        var pi = Array(count: n + 1, repeatedValue: 0)
        var k:Int = -1
        pi[0] = -1
        
        for i in 0..<n {
            while (k >= 0 && (str[str.startIndex.advancedBy(k)] != str[str.startIndex.advancedBy(i)])) {
                k = pi[k]
            }
            k+=1
            pi[i + 1] = k
        }
        
        return pi
    }
    
    // Knuth-Morris Pratt algorithm
    private func KMP(text:String, pattern: String) -> [Int] {
        
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
    
    public override func processWork(node:FMNode, fromNode:FMNode, work: FMWork) -> SearchResult {
        let searchWork:SearchWork = work as! SearchWork
        let textFoundAt:[Int] = KMP(getTextToSearch(searchWork.peerCount, peerNumber: searchWork.peerNumber), pattern: searchWork.searchTerm)
        
        return SearchResult(numberOfOccurrences: textFoundAt.count)
    }
    
    public override func mergeResults(node:FMNode, nodeToResult: [FMNode:FMResult]) -> Void {
        var totalNumberOfOccurrences:Int = 0
        for (n, result) in nodeToResult {
            let searchResult = result as! SearchResult
            NSLog("Received result from node " + n.description)
            totalNumberOfOccurrences += searchResult.numberOfOccurrences
        }
                searchLog("The word '\(self.searchTerm!)' was found in \(totalNumberOfOccurrences) times in the text.\n")
        SwiftEventBus.post(SearchEventBusEvents.searchComplete)
    }

    public override func onPeerConnect(myNode:FMNode, connectedNode:FMNode) {
        SwiftEventBus.post(FogMachineEventBusEvents.onPeerConnect)
    }

    public override func onPeerDisconnect(myNode:FMNode, disconnectedNode:FMNode) {
        SwiftEventBus.post(FogMachineEventBusEvents.onPeerDisconnect)
    }

    public func searchLog(format:String) {
        NSLog(format)
        self.onLog(format)
    }

    public override func onLog(format:String) {
        SwiftEventBus.post(SearchEventBusEvents.onLog, sender:format)
    }
}
