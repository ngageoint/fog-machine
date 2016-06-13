import Foundation

class VanKreveldSweepEventNode {
    let eventType: VanKreveldEventType
    let cell: VanKreveldCell
    
    init(eventType: VanKreveldEventType, cell: VanKreveldCell) {
        self.eventType = eventType
        self.cell = cell
    }
}