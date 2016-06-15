import Foundation
import FogMachine

public class SearchResult: FMResult {

    let numberOfOccurrences:Int

    init (numberOfOccurrences: Int) {
        self.numberOfOccurrences = numberOfOccurrences
        super.init()
    }

    required public init(coder decoder: NSCoder) {
        self.numberOfOccurrences = decoder.decodeIntegerForKey("numberOfOccurrences")
        super.init(coder: decoder)
    }

    public override func encodeWithCoder(coder: NSCoder) {
        super.encodeWithCoder(coder);
        coder.encodeInteger(numberOfOccurrences, forKey: "numberOfOccurrences")
    }
}
