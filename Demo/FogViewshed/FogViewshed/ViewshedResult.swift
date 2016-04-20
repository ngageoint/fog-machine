import Foundation
import MapKit
import Fog

public class ViewshedResult: FMResult {

    let viewshedResult:UIImage //[[Int]]
    
    init (viewshedResult: UIImage) {
        self.viewshedResult = viewshedResult
        super.init()
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

