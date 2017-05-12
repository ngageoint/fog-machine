import Foundation
import FogMachine

open class ViewshedWork: FMWork {
    
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
        sectorCount = decoder.decodeInteger(forKey: "sectorCount")
        sectorNumber = decoder.decodeInteger(forKey: "sectorNumber")
        observer = decoder.decodeObject(forKey: "observer") as! Observer
        viewshedAlgorithmName = ViewshedAlgorithmName(rawValue: decoder.decodeObject(forKey: "viewshedAlgorithmName") as! String)!
        
        super.init(coder: decoder)
    }
    
    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(sectorCount, forKey: "sectorCount")
        coder.encode(sectorNumber, forKey: "sectorNumber")
        coder.encode(observer, forKey: "observer")
        coder.encode(viewshedAlgorithmName.rawValue, forKey: "viewshedAlgorithmName")
    }
}

