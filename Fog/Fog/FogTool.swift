import Foundation
import MultipeerConnectivity

public class FogTool {
    
    //Swift 3 will enable generic typealias', but until then use non-generic alias'
    //public typealias selfWorkDefinition<T: Work> = (T, Bool) -> ()
    public typealias WorkDividerDefinition = (currentQuadrant: Int, numberOfQuadrants: Int, metadata: AnyObject) -> (Work)
    public typealias LogDefinition = (peerName: String) -> ()
    public typealias SelfWorkDefinition = (selfWork: Work, hasPeers: Bool) -> ()
    public typealias ProcessResultDefinition = (result: [String: MPCSerializable], fromPeerId: MCPeerID) -> ()
    public typealias VoidDefinition = (() -> ())
    
    public var workDivider: WorkDividerDefinition
    public var log: LogDefinition
    public var selfWork: SelfWorkDefinition!
    public var processResult: ProcessResultDefinition!
    public var completeWork: VoidDefinition!
    
    public init(workDivider: WorkDividerDefinition, log: LogDefinition, selfWork: SelfWorkDefinition, processResult: ProcessResultDefinition, completeWork: VoidDefinition) {
        self.workDivider = workDivider
        self.log = log
        self.selfWork = selfWork
        self.processResult = processResult
        self.completeWork = completeWork
    }
}