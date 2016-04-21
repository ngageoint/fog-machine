import Foundation
import FogMachine
import SwiftEventBus

public class ViewshedTool : FMTool {
    
    public var createWorkObserver:Observer?
    
    public override init() {
        super.init()
    }
    
    public override func name() -> String {
        return "Viewshed Tool for observer at (\(createWorkObserver!.coordinate.latitude), \(createWorkObserver!.coordinate.longitude))"
    }
    
    public override func createWork(node:FMNode, nodeNumber:UInt, numberOfNodes:UInt) -> ViewshedWork {
        return ViewshedWork(numberOfQuadrants: Int(numberOfNodes), whichQuadrant: Int(nodeNumber), observer: createWorkObserver!)
    }
    
    public override func processWork(node:FMNode, fromNode:FMNode, work: FMWork) -> ViewshedResult {
        //let viewshedWork = work as! ViewshedWork
        
//        self.viewshedPalette.setupNewPalette(observer)
//        if (observer.algorithm == ViewshedAlgorithm.FranklinRay) {
//            let obsViewshed = ViewshedFog(elevation: self.viewshedPalette.getHgtElevation(), observer: observer, numberOfQuadrants: numberOfQuadrants, whichQuadrant: whichQuadrant)
//            self.viewshedPalette.viewshedResults = obsViewshed.viewshedParallel()
//        } else if (observer.algorithm == ViewshedAlgorithm.VanKreveld) {
//            let kreveld: KreveldViewshed = KreveldViewshed()
//            let observerPoints: ElevationPoint = ElevationPoint (xCoord: observer.xCoord, yCoord: observer.yCoord, h: observer.elevation)
//            self.viewshedPalette.viewshedResults = kreveld.parallelKreveld(self.viewshedPalette.getHgtElevation(), observPt: observerPoints, radius: observer.getViewshedSrtm3Radius(), numOfPeers: numberOfQuadrants, quadrant2Calc: whichQuadrant)
//        }
//        
//        let result = ViewshedResult(viewshedResult: self.viewshedPalette.viewshedImage)
        if(fromNode != node) {
            sleep(12)
        } else {
            sleep(2)
        }
        
        return ViewshedResult(viewshedResult: UIImage())
    }
    
    public override func mergeResults(node:FMNode, nodeToResult: [FMNode:FMResult]) -> Void {
        SwiftEventBus.post("viewShedComplete")
    }
    
    public override func onPeerConnect(myNode:FMNode, connectedNode:FMNode) {
        SwiftEventBus.post("onPeerConnect")
    }
    
    public override func onPeerDisconnect(myNode:FMNode, disconnectedNode:FMNode) {
        SwiftEventBus.post("onPeerDisconnect")
    }
}