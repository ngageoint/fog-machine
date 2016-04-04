import Foundation
import Fog

struct SearchWork: MPCSerializable {
    let lowerBound: String
    let upperBound: String
    let searchTerm: String
    let assignedTo: String
    let searchResults: String
    let searchInitiator: String
    
    var mpcSerialized : NSData {
        return NSKeyedArchiver.archivedDataWithRootObject([FogSearch.LowerBoundKey: lowerBound, FogSearch.UpperBoundKey: upperBound, FogSearch.SearchTermKey: searchTerm, FogSearch.AssignedToKey: assignedTo, FogSearch.SearchResultsKey: searchResults, FogSearch.SearchInitiatorKey: searchInitiator])
    }
    
    init (lowerBound: String, upperBound: String, searchTerm: String, assignedTo: String, searchResults: String, searchInitiator: String) {
        self.lowerBound = lowerBound
        self.upperBound = upperBound
        self.searchTerm = searchTerm
        self.assignedTo = assignedTo
        self.searchResults = searchResults
        self.searchInitiator = searchInitiator
    }
    
    init (mpcSerialized: NSData) {
        let workData = NSKeyedUnarchiver.unarchiveObjectWithData(mpcSerialized) as! [String: String]
        lowerBound = workData[FogSearch.LowerBoundKey]!
        upperBound = workData[FogSearch.UpperBoundKey]!
        searchTerm = workData[FogSearch.SearchTermKey]!
        assignedTo = workData[FogSearch.AssignedToKey]!
        searchResults = workData[FogSearch.SearchResultsKey]!
        searchInitiator = workData[FogSearch.SearchInitiatorKey]!
    }
}


struct SearchWorkArray: MPCSerializable {
    let array: Array<SearchWork>
    
    var mpcSerialized: NSData {
        return NSKeyedArchiver.archivedDataWithRootObject(array.map { $0.mpcSerialized })
    }
    
    init(array: Array<SearchWork>) {
        self.array = array
    }
    
    init(mpcSerialized: NSData) {
        let dataArray = NSKeyedUnarchiver.unarchiveObjectWithData(mpcSerialized) as! [NSData]
        array = dataArray.map { return SearchWork(mpcSerialized: $0) }
    }
}
