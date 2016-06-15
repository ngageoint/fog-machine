import Foundation
import FogMachine

public class ViewshedWork: FMWork {
    
    let sectorCount: Int
    let sectorNumber: Int
    let observer: Observer
    
    let viewshedAlgorithmName: ViewshedAlgorithmName

    init (sectorCount: Int, sectorNumber: Int, observer: Observer, viewshedAlgorithmName: ViewshedAlgorithmName) {
        self.sectorCount = sectorCount
        self.sectorNumber = sectorNumber
        self.observer = observer
        self.viewshedAlgorithmName = viewshedAlgorithmName
        super.init()
    }
    
    required public init(coder decoder: NSCoder) {
        self.sectorCount = decoder.decodeIntegerForKey("sectorCount")
        self.sectorNumber = decoder.decodeIntegerForKey("sectorNumber")
        self.observer = decoder.decodeObjectForKey("observer") as! Observer
        self.viewshedAlgorithmName = ViewshedAlgorithmName(rawValue: decoder.decodeObjectForKey("viewshedAlgorithmName") as! String)!
        
        super.init(coder: decoder)
    }
    
    public override func encodeWithCoder(coder: NSCoder) {
        super.encodeWithCoder(coder);
        coder.encodeInteger(sectorCount, forKey: "sectorCount")
        coder.encodeInteger(sectorNumber, forKey: "sectorNumber")
        coder.encodeObject(observer, forKey: "observer")
        coder.encodeObject(viewshedAlgorithmName.rawValue, forKey: "viewshedAlgorithmName")
    }
}

