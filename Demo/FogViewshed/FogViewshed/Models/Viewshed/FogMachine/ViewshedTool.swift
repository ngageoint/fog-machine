import Foundation
import FogMachine
import SwiftEventBus

open class ViewshedTool: FMTool {
    
    open var createWorkViewshedObserver: Observer?
    open var createWorkViewshedAlgorithmName: ViewshedAlgorithmName?
    
    public override init() {
        super.init()
    }
    
    open override func id() -> UInt32 {
        return 4230345579
    }
    
    open override func name() -> String {
        return "Viewshed Tool with " + createWorkViewshedAlgorithmName!.rawValue + " algorithm for observer at (\(createWorkViewshedObserver!.position.latitude), \(createWorkViewshedObserver!.position.longitude))"
    }
    
    open override func createWork(_ node: FMNode, nodeNumber: UInt, numberOfNodes: UInt) -> ViewshedWork {
        return ViewshedWork(sectorCount: Int(numberOfNodes), sectorNumber: Int(nodeNumber), observer: createWorkViewshedObserver!, viewshedAlgorithmName: createWorkViewshedAlgorithmName!)
    }
    
    open override func processWork(_ node: FMNode, fromNode: FMNode, work: FMWork) -> ViewshedResult {
        let viewshedWork = work as! ViewshedWork
        
        // draw the pin if it doesn't exist
        SwiftEventBus.post(ViewshedEventBusEvents.addObserverPin, sender: viewshedWork.observer)
        
        // make the sector
        let angleSize: Double = (2 * Double.pi) / Double(viewshedWork.sectorCount)
        let startAngle: Double = angleSize * Double(viewshedWork.sectorNumber)
        let endAngle: Double = angleSize * Double(viewshedWork.sectorNumber + 1)
        let sector: Sector = Sector(center: viewshedWork.observer.position, startAngleInRadans: startAngle, endAngleInRadans: endAngle, radiusInMeters: viewshedWork.observer.radiusInMeters)
        
        var axisOrientedBoundingBox: AxisOrientedBoundingBox
        var perimeter: Perimeter
        // get bounding box for sector
        if(viewshedWork.sectorCount == 1) {
            // special case for no peers
            axisOrientedBoundingBox = BoundingBoxUtility.getBoundingBox(viewshedWork.observer.position, radiusInMeters: viewshedWork.observer.radiusInMeters)
        } else {
            axisOrientedBoundingBox = sector.getBoundingBox()
        }
        
        // read elevation data
        viewshedLog("Start reading in elevation data")
        let dataReadTimer: FMTimer = FMTimer()
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
        let viewshedTimer: FMTimer = FMTimer()
        viewshedTimer.start()
        var viewsehdAlgorithm: ViewsehdAlgorithm
        
        if(viewshedWork.viewshedAlgorithmName == ViewshedAlgorithmName.VanKreveld) {
            viewsehdAlgorithm = VanKreveldViewshed(elevationDataGrid: elevationDataGrid, observer: viewshedWork.observer)
        } else {
            viewsehdAlgorithm = FranklinRayViewshed(elevationDataGrid: elevationDataGrid, perimeter: perimeter, observer: viewshedWork.observer)
        }
        
        let viewshedDataGrid: DataGrid = viewsehdAlgorithm.runViewshed()
        viewshedLog("Ran viewshed in " + String(format: "%.3f", viewshedTimer.stop()) + " seconds")
        

        SwiftEventBus.post(ViewshedEventBusEvents.drawGridOverlay, sender: ImageUtility.generateViewshedOverlay(viewshedDataGrid))
        
        return ViewshedResult(dataGrid: viewshedDataGrid)
    }
    
    open override func mergeResults(_ node: FMNode, nodeToResult: [FMNode: FMResult]) -> Void {
        for (n, result) in nodeToResult {
            // if this is not me
            if(node != n) {
                let viewshedResult = result as! ViewshedResult
                NSLog("Received result from node " + n.description)
                SwiftEventBus.post(ViewshedEventBusEvents.drawGridOverlay, sender: ImageUtility.generateViewshedOverlay(viewshedResult.dataGrid))
            }
        }
        SwiftEventBus.post(ViewshedEventBusEvents.viewshedComplete)
    }
    
    open override func onPeerConnect(_ myNode: FMNode, connectedNode: FMNode) {
        SwiftEventBus.post(FogMachineEventBusEvents.onPeerConnect)
    }
    
    open override func onPeerDisconnect(_ myNode: FMNode, disconnectedNode: FMNode) {
        SwiftEventBus.post(FogMachineEventBusEvents.onPeerDisconnect)
    }
    
    open func viewshedLog(_ format: String) {
        NSLog(format)
        onLog(format)
    }
    
    open override func onLog(_ format: String) {
        SwiftEventBus.post(ViewshedEventBusEvents.onLog, sender: format as AnyObject)
    }
}
