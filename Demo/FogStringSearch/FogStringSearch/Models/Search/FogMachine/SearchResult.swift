import Foundation
import FogMachine

open class SearchResult: FMResult {

    let numberOfOccurrences: Int

    init (numberOfOccurrences: Int) {
        self.numberOfOccurrences = numberOfOccurrences
        super.init()
    }

    required public init(coder decoder: NSCoder) {
        self.numberOfOccurrences = decoder.decodeInteger(forKey: "numberOfOccurrences")
        super.init(coder: decoder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(numberOfOccurrences, forKey: "numberOfOccurrences")
    }
}
