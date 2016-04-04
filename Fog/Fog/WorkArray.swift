import Foundation
import UIKit
import MapKit

public struct WorkArray<T: Work>: MPCSerializable {
    
    let array: Array<T>
    
    public var mpcSerialized: NSData {
        return NSKeyedArchiver.archivedDataWithRootObject(array.map { $0.mpcSerialized })
    }
    
    public init(array: Array<T>) {
        self.array = array
    }
    
    public init(mpcSerialized: NSData) {
        let dataArray = NSKeyedUnarchiver.unarchiveObjectWithData(mpcSerialized) as! [NSData]
        array = dataArray.map { return T(mpcSerialized: $0) }
    }
}
