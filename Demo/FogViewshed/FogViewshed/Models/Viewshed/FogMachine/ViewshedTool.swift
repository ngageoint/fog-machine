import Foundation
import FogMachine
import SwiftEventBus

public class ViewshedTool : FMTool {
    
    public var createWorkViewshedObserver:Observer?
    public var createWorkViewshedAlgorithmName:ViewshedAlgorithmName?
    
    public override init() {
        super.init()
    }
    
    public override func name() -> String {
        return "Viewshed Tool with " + createWorkViewshedAlgorithmName!.rawValue + " algorithm for observer at (\(createWorkViewshedObserver!.position.latitude), \(createWorkViewshedObserver!.position.longitude))"
    }
    
    public override func createWork(node:FMNode, nodeNumber:UInt, numberOfNodes:UInt) -> ViewshedWork {
        return ViewshedWork(sectorCount: Int(numberOfNodes), sectorNumber: Int(nodeNumber), observer: createWorkViewshedObserver!, viewshedAlgorithmName: createWorkViewshedAlgorithmName!)
    }
    
    public override func processWork(node:FMNode, fromNode:FMNode, work: FMWork) -> ViewshedResult {
        let viewshedWork = work as! ViewshedWork
        
        // make the sector
        let angleSize:Double = (2*M_PI)/Double(viewshedWork.sectorCount)
        let startAngle:Double = angleSize*Double(viewshedWork.sectorNumber)
        let endAngle:Double = angleSize*Double(viewshedWork.sectorNumber + 1)
        let sector:Sector = Sector(center: viewshedWork.observer.position, startAngleInRadans: startAngle, endAngleInRadans: endAngle, radiusInMeters: viewshedWork.observer.radiusInMeters)
        
        var axisOrientedBoundingBox:AxisOrientedBoundingBox
        var perimeter:Perimeter
        // get bounding box for sector
        if(viewshedWork.sectorCount == 1) {
            // special case for no peers
            axisOrientedBoundingBox = BoundingBoxUtility.getBoundingBox(viewshedWork.observer.position, radiusInMeters: viewshedWork.observer.radiusInMeters)
        } else {
            axisOrientedBoundingBox = sector.getBoundingBox()
        }
        
        // read elevation data
        NSLog("Start reading in elevation data")
        let dataReadTimer:FMTimer = FMTimer()
        dataReadTimer.start()
        let elevationDataGrid:DataGrid = HGTManager.getElevationGrid(axisOrientedBoundingBox)
        NSLog("Read elevation data in " + String(format: "%.3f", dataReadTimer.stop()) + " seconds")
        
        if(viewshedWork.sectorCount == 1) {
            perimeter = RectangularPerimeter(dataGrid: elevationDataGrid)
        } else {
            perimeter = SectorPerimeter(dataGrid: elevationDataGrid, sector: sector)
        }
        
        // run viewshed on data
        NSLog("Start running viewshed")
        let viewshedTimer:FMTimer = FMTimer()
        viewshedTimer.start()
        let franklinRayViewshed:FranklinRayViewshed = FranklinRayViewshed(elevationDataGrid: elevationDataGrid, perimeter: perimeter, observer: viewshedWork.observer)
        let viewshed:[[Int]] = franklinRayViewshed.runViewshed()
        NSLog("Ran viewshed in " + String(format: "%.3f", viewshedTimer.stop()) + " seconds")
        
        let viewshedDataGrid:DataGrid = DataGrid(data: viewshed, boundingBoxAreaExtent: elevationDataGrid.boundingBoxAreaExtent, resolution: elevationDataGrid.resolution)
        SwiftEventBus.post("drawViewshed", sender:ViewshedImageUtility.generateViewshedOverlay(viewshedDataGrid))
        
        return ViewshedResult(dataGrid: viewshedDataGrid)
    }
    
    public override func mergeResults(node:FMNode, nodeToResult: [FMNode:FMResult]) -> Void {
        SwiftEventBus.post("viewShedComplete")
        
        for (n, result) in nodeToResult {
            let viewshedResult = result as! ViewshedResult
            NSLog("Received result from node " + node.description)
            if(n != node) {
                SwiftEventBus.post("drawViewshed", sender:ViewshedImageUtility.generateViewshedOverlay(viewshedResult.dataGrid))
            }
        }
    }
    
    public override func onPeerConnect(myNode:FMNode, connectedNode:FMNode) {
        SwiftEventBus.post("onPeerConnect")
    }
    
    public override func onPeerDisconnect(myNode:FMNode, disconnectedNode:FMNode) {
        SwiftEventBus.post("onPeerDisconnect")
    }
    
    public override func onLog(format:String) {
        SwiftEventBus.post("onLog", sender:format)
    }
}