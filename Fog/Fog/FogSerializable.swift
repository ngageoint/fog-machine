import Foundation

public protocol FogSerializable {
    init(serializedData: [String:NSObject])
    func getDataToSerialize() -> [String:NSObject]
}
