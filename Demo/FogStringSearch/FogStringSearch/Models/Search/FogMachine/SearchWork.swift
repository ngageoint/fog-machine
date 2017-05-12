import Foundation
import FogMachine

open class SearchWork: FMWork {

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
        self.peerCount = decoder.decodeInteger(forKey: "peerCount")
        self.peerNumber = decoder.decodeInteger(forKey: "peerNumber")
        self.searchTerm = decoder.decodeObject(forKey: "searchTerm") as! String

        super.init(coder: decoder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(peerCount, forKey: "peerCount")
        coder.encode(peerNumber, forKey: "peerNumber")
        coder.encode(searchTerm, forKey: "searchTerm")
    }
}
