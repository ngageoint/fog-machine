import Foundation
import SwiftEventBus
import FogMachine

open class ElevationTool {

    open var elevationObserver: Observer
    
    public init(elevationObserver: Observer) {
        self.elevationObserver = elevationObserver
    }

    open func drawElevationData() {
        let axisOrientedBoundingBox: AxisOrientedBoundingBox = BoundingBoxUtility.getBoundingBox(elevationObserver.position, radiusInMeters: elevationObserver.radiusInMeters)

        // read elevation data
        elevationLog("Start reading in elevation data")
        let dataReadTimer: FMTimer = FMTimer()
        dataReadTimer.start()
        let elevationDataGrid: DataGrid = HGTManager.getElevationGrid(axisOrientedBoundingBox, resolution: Srtm.SRTM3_RESOLUTION)
        elevationLog("Read elevation data in " + String(format: "%.3f", dataReadTimer.stop()) + " seconds")
        SwiftEventBus.post(ViewshedEventBusEvents.drawGridOverlay, sender:ImageUtility.generateElevationOverlay(elevationDataGrid))
    }
    
    open func draw3dElevationData() {
        let axisOrientedBoundingBox: AxisOrientedBoundingBox = BoundingBoxUtility.getBoundingBox(elevationObserver.position, radiusInMeters: elevationObserver.radiusInMeters)
        
        // read elevation data
        elevationLog("Start reading in elevation data")
        let dataReadTimer: FMTimer = FMTimer()
        dataReadTimer.start()
        let elevationDataGrid: DataGrid = HGTManager.getElevationGrid(axisOrientedBoundingBox, resolution: Srtm.SRTM3_RESOLUTION)
        elevationLog("Read elevation data in " + String(format: "%.3f", dataReadTimer.stop()) + " seconds")
        SwiftEventBus.post(ViewshedEventBusEvents.viewshed3d, sender: elevationDataGrid)
    }

    open func elevationLog(_ format: String) {
        NSLog(format)
        SwiftEventBus.post(ViewshedEventBusEvents.onLog, sender: format as AnyObject)
    }
}
