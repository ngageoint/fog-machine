import Foundation
import FogMachine

open class ViewshedResult: FMResult {

    let dataGrid:DataGrid
    
    init (dataGrid: DataGrid) {
        self.dataGrid = dataGrid
        super.init()
    }
    
    required public init(coder decoder: NSCoder) {
        dataGrid = decoder.decodeObject(forKey: "dataGrid") as! DataGrid
        super.init(coder: decoder)
    }
    
    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(dataGrid, forKey: "dataGrid")
    }
}

