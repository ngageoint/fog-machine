import Foundation
import FogMachine

public class SearchWork: FMWork {

    let peerCount: Int
    let peerNumber: Int
    let searchTerm: String

    init (peerCount: Int, peerNumber: Int, searchTerm: String) {
        self.peerCount = peerCount
        self.peerNumber = peerNumber
        self.searchTerm = searchTerm
        super.init()
    }

    required public init(coder decoder: NSCoder) {
        self.peerCount = decoder.decodeIntegerForKey("peerCount")
        self.peerNumber = decoder.decodeIntegerForKey("peerNumber")
        self.searchTerm = decoder.decodeObjectForKey("searchTerm") as! String

        super.init(coder: decoder)
    }

    public override func encodeWithCoder(coder: NSCoder) {
        super.encodeWithCoder(coder);
        coder.encodeInteger(peerCount, forKey: "peerCount")
        coder.encodeInteger(peerNumber, forKey: "peerNumber")
        coder.encodeObject(searchTerm, forKey: "searchTerm")
    }
}
