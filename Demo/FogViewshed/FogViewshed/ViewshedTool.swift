import Foundation
import Fog
import SwiftEventBus

public class ViewshedTool : FogTool {
    
    public var createWorkObserver:Observer?
    
    public override init() {
        super.init()
    }
    
    public override func name() -> String {
        return "Viewshed Tool for observer at (\(createWorkObserver!.coordinate.latitude), \(createWorkObserver!.coordinate.longitude))"
    }
    
    public override func createWork(node:Node, nodeNumber:UInt, numberOfNodes:UInt) -> ViewshedWork {
        return ViewshedWork(numberOfQuadrants: Int(numberOfNodes), whichQuadrant: Int(nodeNumber), observer: createWorkObserver!);
    }
    
    public override func processWork(node:Node, fromNode:Node, work: FogWork) -> ViewshedResult {
        let processWorkTimer = Timer()
        
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
            sleep(10)
        }
        
        processWorkTimer.start()
        return ViewshedResult(processWorkTime: processWorkTimer.stop(), viewshedResult: UIImage());
    }
    
    public override func mergeResults(node:Node, nodeToResult :[Node:FogResult]) -> Void {
        
        SwiftEventBus.post("viewShedComplete")
    }
    
    public override func onPeerConnect(myNode:Node, connectedNode:Node) {
        SwiftEventBus.post("onPeerConnect")
    }
    
    public override func onPeerDisconnect(myNode:Node, disconnectedNode:Node) {
        SwiftEventBus.post("onPeerDisconnect")
    }
}