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
        
        var axisOrientedBoundingBox:AxisOrientedBoundingBox
        // get bounding box for sector
        if(viewshedWork.sectorCount == 1) {
            axisOrientedBoundingBox = BoundingBoxUtility.getBoundingBox(viewshedWork.observer.position, radiusInMeters: viewshedWork.observer.radiusInMeters)
        } else {
            // TODO sector calculation
        }
        
        // TODO : remove me
        axisOrientedBoundingBox = BoundingBoxUtility.getBoundingBox(viewshedWork.observer.position, radiusInMeters: viewshedWork.observer.radiusInMeters)
        // read elevation data
        let elevationDataGrid:ElevationDataGrid = HGTManager.getElevationGrid(axisOrientedBoundingBox)
        
        // run viewshed on data
        let franklinRayViewshed:FranklinRayViewshed = FranklinRayViewshed(elevationDataGrid: elevationDataGrid, observer: viewshedWork.observer)
        
        let viewshed:[[Int]] = franklinRayViewshed.runViewshed()

        let result = ViewshedResult(viewshedResult: ViewshedImageUtility.toUIImage(viewshed))
        if(fromNode != node) {
            sleep(12)
        } else {
            sleep(5)
        }
        
        return ViewshedResult(viewshedResult: UIImage())
    }
    
    public override func mergeResults(node:FMNode, nodeToResult: [FMNode:FMResult]) -> Void {
        sleep(5)
        SwiftEventBus.post("viewShedComplete")
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