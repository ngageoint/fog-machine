import Foundation
import FogMachine
import SwiftEventBus

public class ViewshedTool : FMTool {
    
    public var createWorkViewshedObserver:Observer?
    public var createWorkViewshedAlgorithmName:ViewshedAlgorithmName?
    
    public override init() {
        super.init()
    }
    
    public override func id() -> UInt32 {
        return 4230345579
    }
    
    public override func name() -> String {
        return "Viewshed Tool with " + createWorkViewshedAlgorithmName!.rawValue + " algorithm for observer at (\(createWorkViewshedObserver!.position.latitude), \(createWorkViewshedObserver!.position.longitude))"
    }
    
    public override func createWork(node:FMNode, nodeNumber:UInt, numberOfNodes:UInt) -> ViewshedWork {
        return ViewshedWork(sectorCount: Int(numberOfNodes), sectorNumber: Int(nodeNumber), observer: createWorkViewshedObserver!, viewshedAlgorithmName: createWorkViewshedAlgorithmName!)
    }
    
    public override func processWork(node:FMNode, fromNode:FMNode, work: FMWork) -> ViewshedResult {
        let viewshedWork = work as! ViewshedWork
        
        // draw the pin if it doesn't exist
        SwiftEventBus.post(ViewshedEventBusEvents.addObserverPin, sender:viewshedWork.observer)
        
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
        viewshedLog("Start reading in elevation data")
        let dataReadTimer:FMTimer = FMTimer()
        dataReadTimer.start()
        let elevationDataGrid:DataGrid = HGTManager.getElevationGrid(axisOrientedBoundingBox, resolution: Srtm.SRTM3_RESOLUTION)
        viewshedLog("Read elevation data in " + String(format: "%.3f", dataReadTimer.stop()) + " seconds")
        
        if(viewshedWork.sectorCount == 1) {
            perimeter = RectangularPerimeter(dataGrid: elevationDataGrid)
        } else {
            perimeter = SectorPerimeter(dataGrid: elevationDataGrid, sector: sector)
        }
        
        // run viewshed on data
        viewshedLog("Start running viewshed")
        let viewshedTimer:FMTimer = FMTimer()
        viewshedTimer.start()
        var viewsehdAlgorithm:ViewsehdAlgorithm
        
        if(viewshedWork.viewshedAlgorithmName == ViewshedAlgorithmName.VanKreveld) {
            viewsehdAlgorithm = VanKreveldViewshed(elevationDataGrid: elevationDataGrid, observer: viewshedWork.observer)
        } else {
            viewsehdAlgorithm = FranklinRayViewshed(elevationDataGrid: elevationDataGrid, perimeter: perimeter, observer: viewshedWork.observer)
        }
        
        let viewshedDataGrid:DataGrid = viewsehdAlgorithm.runViewshed()
        viewshedLog("Ran viewshed in " + String(format: "%.3f", viewshedTimer.stop()) + " seconds")
        
        // if this is not me
        if(node != fromNode) {
            SwiftEventBus.post(ViewshedEventBusEvents.drawGridOverlay, sender:ImageUtility.generateViewshedOverlay(viewshedDataGrid))
        }
        
        return ViewshedResult(dataGrid: viewshedDataGrid)
    }
    
    public override func mergeResults(node:FMNode, nodeToResult: [FMNode:FMResult]) -> Void {
        for (n, result) in nodeToResult {
            let viewshedResult = result as! ViewshedResult
            NSLog("Received result from node " + n.description)
            SwiftEventBus.post(ViewshedEventBusEvents.drawGridOverlay, sender:ImageUtility.generateViewshedOverlay(viewshedResult.dataGrid))
        }
        SwiftEventBus.post(ViewshedEventBusEvents.viewshedComplete)
    }
    
    public override func onPeerConnect(myNode:FMNode, connectedNode:FMNode) {
        SwiftEventBus.post(FogMachineEventBusEvents.onPeerConnect)
    }
    
    public override func onPeerDisconnect(myNode:FMNode, disconnectedNode:FMNode) {
        SwiftEventBus.post(FogMachineEventBusEvents.onPeerDisconnect)
    }
    
    public func viewshedLog(format:String) {
        NSLog(format)
        self.onLog(format)
    }
    
    public override func onLog(format:String) {
        SwiftEventBus.post(ViewshedEventBusEvents.onLog, sender:format)
    }
}