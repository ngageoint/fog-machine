import Foundation
import FogMachine

public class SearchWork: FMWork {

    let peerCount: Int
    let peerNumber: Int
    let searchTerm: String
    
    enum SearchWorkCodingKeys: String, CodingKey {
        case peerCount
        case peerNumber
        case searchTerm
    }

    init (peerCount: Int, peerNumber: Int, searchTerm: String) {
        self.peerCount = peerCount
        self.peerNumber = peerNumber
        self.searchTerm = searchTerm
        super.init()
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: SearchWorkCodingKeys.self)
        self.peerCount = try container.decode(Int.self, forKey: .peerCount)
        self.peerNumber = try container.decode(Int.self, forKey: .peerNumber)
        self.searchTerm = try container.decode(String.self, forKey: .searchTerm)

        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: SearchWorkCodingKeys.self)
        try container.encode(peerCount, forKey: .peerCount)
        try container.encode(peerNumber, forKey: .peerNumber)
        try container.encode(searchTerm, forKey: .searchTerm)
    }
}
