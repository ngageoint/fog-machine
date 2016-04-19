import Foundation
import MapKit
import Fog

public class ViewshedResult: FogResult {

    let viewshedResult:UIImage //[[Int]]
    
    init (processWorkTime:CFAbsoluteTime, viewshedResult: UIImage) {
        self.viewshedResult = viewshedResult
        super.init(processWorkTime: processWorkTime)
    }
    
    required public init(coder decoder: NSCoder) {
        self.viewshedResult = decoder.decodeObjectForKey("viewshed") as! UIImage
        super.init(coder: decoder)
    }
    
    public override func encodeWithCoder(coder: NSCoder) {
        super.encodeWithCoder(coder);
        coder.encodeObject(viewshedResult, forKey: "viewshed")
    }

    
}

