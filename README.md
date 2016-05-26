# Fog Machine Framework

![viewshed on three phones](Demo/FogViewshed/Screenshots/0.png)

Fog Machine is an iOS Swift framework for parallel processing.  Solve hard problems fast with the Fog Machine framework.

The Fog Machine framework is a research and development effort to harness the computing power of multiple, locally connected iOS devices.  By using a mesh-network of mobile devices, parallel processing techniques allows Fog Machine to analyze data and answer complex questions quickly and efficiently.  Parallel processing over mesh-networks reduces the overall time to solve problems by taking advantage of shared resources (processors, memory, etc.).  The communication relies on a wifi or bluetooth chipset and is built on Apple's Multipeer Connectivity framework.

There is a simple demo app that calculates the viewshed of a position.  A viewshed is the geographical area that is visible from a location. It includes all surrounding points in line-of-sight with the location and excludes points that are beyond the horizon or obstructed by terrain and other features.

FogMachine was developed at the National Geospatial-Intelligence Agency (NGA) in collaboration with BIT Systems. The government has "unlimited rights" and is releasing this software to increase the impact of government investments by providing developers with the opportunity to take things in new directions. The software use, modification, and distribution rights are stipulated within the Apache license.

## Build

Fog Machine uses [CocoaPods](https://cocoapods.org/) for dependency management.   

Install all dependencies:
```bash
pod cache clean --all
pod install
```

## Usage

The Fog Machine framework provides a simple lifecycle for your app to use.  After extending FMTool, you can immediately start running your tasks in parallel.

```swift
// What do I need help with?
FogMachine.fogMachineInstance.setTool(MyCoolTool())

// Look for friends/devices to help me
FogMachine.fogMachineInstance.startSearchForPeers()

// Run MyCoolTool on all the nodes in the Fog Machine mesh-network
FogMachine.fogMachineInstance.execute()
```

## Requirements

Fog Machine requires iOS 8.4+.

## Pull Requests

If you'd like to contribute to this project, please make a pull request. We'll review the pull request and discuss the changes. All pull request contributions to this project will be released under the Apache license.

Software source code previously released under an open source license and then modified by NGA staff is considered a "joint work" (see 17 USC § 101); it is partially copyrighted, partially public domain, and as a whole is protected by the copyrights of the non-government authors and must be released according to the terms of the original open source license.

## Acknowledgements

Fog Machine makes use of the following open source projects:
- **PeerKit**  
*https://github.com/cwas/PeerKit*
This product includes software licensed under the MIT License http://opensource.org/licenses/mit-license.php
- **SwiftEventBus**  
*https://github.com/cesarferreira/SwiftEventBus*
This product includes software licensed under the MIT License http://opensource.org/licenses/mit-license.php
