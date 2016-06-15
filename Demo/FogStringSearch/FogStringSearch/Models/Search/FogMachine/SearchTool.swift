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
                }
            }
        } catch let error as NSError {
            NSLog("Error reading file: \(error.localizedDescription)")
        }
        return textToSearch
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
        
        NSLog("\(searchWork.searchTerm) found in text \(textFoundAt.count) times.")
//        for i in 0..<textFoundAt.count {
//            NSLog("\(textFoundAt[i])")
//        }
        
        return SearchResult(numberOfOccurrences: textFoundAt.count)
    }
    
    public override func mergeResults(node:FMNode, nodeToResult: [FMNode:FMResult]) -> Void {
        var totalNumberOfOccurrences:Int = 0
        for (n, result) in nodeToResult {
            let searchResult = result as! SearchResult
            NSLog("Received result from node " + n.description)
            totalNumberOfOccurrences += searchResult.numberOfOccurrences
        }
        SwiftEventBus.post(SearchEventBusEvents.searchComplete)
    }

    public override func onPeerConnect(myNode:FMNode, connectedNode:FMNode) {
        SwiftEventBus.post(FogMachineEventBusEvents.onPeerConnect)
    }

    public override func onPeerDisconnect(myNode:FMNode, disconnectedNode:FMNode) {
        SwiftEventBus.post(FogMachineEventBusEvents.onPeerDisconnect)
    }

    public func viewshedLog(format:String) {
        NSLog(format)
        self.onLog(format)
    }

    public override func onLog(format:String) {
        SwiftEventBus.post(SearchEventBusEvents.onLog, sender:format)
    }
}
