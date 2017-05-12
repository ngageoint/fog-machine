import Foundation
import Buckets


/**
 
 Finds a viewshed using Van Kreveld's method.  More acurate, but slower.
 
 */
open class VanKreveldViewshed: ViewsehdAlgorithm {
    
    let elevationDataGrid: DataGrid
    let observer: Observer
    
    init(elevationDataGrid: DataGrid, observer: Observer) {
        self.elevationDataGrid = elevationDataGrid
        self.observer = observer
    }
    
    open func runViewshed() -> DataGrid {
        // elevation data
        let elevationGrid: [[Int]] = elevationDataGrid.data
        
        let rowSize: Int =  elevationDataGrid.data.count
        let columnSize: Int = elevationDataGrid.data[0].count
        
        let oxiyi: (Int, Int) = elevationDataGrid.latLonToIndex(observer.position)
        // get the cell the observer exists in
        let oxi: Int = oxiyi.0
        let oyi: Int = oxiyi.1
        var oh: Double = Double(elevationGrid[oyi][oxi]) + observer.elevationInMeters
        // FIXME: if there a better way to deal with this?
        // if the elevation data where the observer is positioned is bad, just set elevation to above sea level
        if(elevationGrid[oyi][oxi] == Srtm.DATA_VOID) {
            oh = observer.elevationInMeters
        }
        let oxd: Double = Double(oxi)
        let oyd: Double = Double(oyi)
        
        let oVKCell = VanKreveldCell(x: oxi, y: oyi, h: oh)
        
        // outputs
        var viewshed: [[Int]] = [[Int]](repeating: [Int](repeating: Viewshed.NO_DATA, count: columnSize), count: rowSize)
        viewshed[oyi][oxi] = Viewshed.OBSERVER
        
        
        func priorityQueueOrder(_ n1: VanKreveldSweepEventNode, _ n2: VanKreveldSweepEventNode) -> Bool {
            let angle1: Double = atan(oVKCell, c2: n1.cell, type: n1.eventType)
            let angle2: Double = atan(oVKCell, c2: n2.cell, type: n2.eventType)
            if(angle1 > angle2) {
                return false
            } else if(angle1 < angle2) {
                return true
            } else {
                let distance1: Double = sqrt(pow(oxd - Double(n1.cell.x), 2) + pow(oyd - Double(n1.cell.y), 2))
                let distance2: Double = sqrt(pow(oxd - Double(n2.cell.x), 2) + pow(oyd - Double(n2.cell.y), 2))
                if(distance1 > distance2) {
                    return false
                } else {
                    return true
                }
            }
        }
        
        //var test:Double = atan(VanKreveldCell(x: 0, y: 0, h: 0),c2:VanKreveldCell(x: 45, y: 45, h: 0), type: VanKreveldEventType.ENTER)
        
        var allCells = PriorityQueue(sortedBy: priorityQueueOrder)
        
        // find min and max for this grid
        for xi in 0 ..< rowSize {
            for yi in 0 ..< columnSize {
        
                // the observer can see itself, don't run this
                if(oxi == xi && oyi == yi) {
                    continue
                }
                
                let elevation_at_xy = elevationGrid[xi][yi]
                if(elevation_at_xy == Srtm.DATA_VOID || elevation_at_xy == Srtm.NO_DATA) {
                    continue
                }
                
                let xyVKCell = VanKreveldCell(x: xi, y: yi, h: Double(elevation_at_xy))
            
                allCells.enqueue(VanKreveldSweepEventNode(eventType: VanKreveldEventType.enter, cell: xyVKCell))
                allCells.enqueue(VanKreveldSweepEventNode(eventType: VanKreveldEventType.center, cell: xyVKCell))
                allCells.enqueue(VanKreveldSweepEventNode(eventType: VanKreveldEventType.exit, cell: xyVKCell))
            }
        }
        
        var kreveldActive: KreveldActiveBinaryTree = KreveldActiveBinaryTree(reference: oVKCell)
        
        while !allCells.isEmpty {
            let currentKreveldSweepEventNode: VanKreveldSweepEventNode = allCells.dequeue()
            let cell: VanKreveldCell = currentKreveldSweepEventNode.cell
            
            switch currentKreveldSweepEventNode.eventType {
                case VanKreveldEventType.enter:
                    kreveldActive.insert(cell)
                case VanKreveldEventType.center:
                    NSLog("cell: \(cell.x), \(cell.y)")
                    let x: Int = cell.x
                    let y: Int = cell.y
                    
                    if (kreveldActive.isVisible(cell)) {
                        viewshed[x][y] = Viewshed.VISIBLE
                    } else {
                        viewshed[x][y] = Viewshed.NOT_VISIBLE
                    }
                case VanKreveldEventType.exit:
                    kreveldActive.delete(cell)
            }
        }
        
        viewshed[oyi][oxi] = Viewshed.OBSERVER
        return DataGrid(data: viewshed, boundingBoxAreaExtent: elevationDataGrid.boundingBoxAreaExtent, resolution: elevationDataGrid.resolution)
    }
    
    func atan(_ c1: VanKreveldCell, c2: VanKreveldCell, type: VanKreveldEventType) -> Double {
        
        let dy: Double = Double(c2.y - c1.y)
        let dx: Double = Double(c2.x - c1.x)
        var angle: Double = 0
        
        if(type == VanKreveldEventType.center) {
            angle = (atan2(dy, dx) + 2 * Double.pi).truncatingRemainder(dividingBy: (2 * Double.pi))
        } else {
            if(type == VanKreveldEventType.enter) {
                angle = 2 * Double.pi
            } else if(type == VanKreveldEventType.exit) {
                angle = 0
            }
            
            for i in 0 ..< 2 {
                for j in 0 ..< 2 {
                    let tAngle = (atan2(dy - 0.5 + Double(i), dx - 0.5 + Double(j)) + 2 * Double.pi).truncatingRemainder(dividingBy: (2 * Double.pi))
                    if(type == VanKreveldEventType.enter) {
                        angle = min(angle, tAngle)
                    } else if(type == VanKreveldEventType.exit) {
                        angle = max(angle, tAngle)
                    }
                }
            }
        }
        return angle
    }
}

