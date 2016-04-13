import Foundation
import MapKit
import Fog

public class ViewshedResult: FogResult {

    let viewshedResult:UIImage //[[Int]]
    
    init (viewshedResult: UIImage) {
        self.viewshedResult = viewshedResult
        super.init()
    }
    
    public required init (serializedData: [String:NSObject]) {
        viewshedResult = serializedData[ViewshedWork.NUMBER_OF_QUADRANTS] as! UIImage
        super.init(serializedData: serializedData)
    }
    
    public override func getDataToSerialize() -> [String:NSObject] {
        return [ViewshedWork.VIEWSHED_RESULT: viewshedResult];
    }

    
}

