import Foundation
import FogMachine

public class ViewshedResult: FMResult {

    let dataGrid:DataGrid
    
    init (dataGrid: DataGrid) {
        self.dataGrid = dataGrid
        super.init()
    }
    
    required public init(coder decoder: NSCoder) {
        self.dataGrid = decoder.decodeObjectForKey("dataGrid") as! DataGrid
        super.init(coder: decoder)
    }
    
    public override func encodeWithCoder(coder: NSCoder) {
        super.encodeWithCoder(coder);
        coder.encodeObject(dataGrid, forKey: "dataGrid")
    }
}

