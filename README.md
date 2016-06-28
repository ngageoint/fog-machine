# Fog Machine Framework

![viewshed on three phones](Screenshots/overview_1400_1040.png)

Fog Machine is an iOS Swift framework for parallel processing.  Solve hard problems fast with the Fog Machine framework.

The Fog Machine framework is a research and development effort to harness the computing power of multiple, locally connected iOS devices.  By using a mesh-network of mobile devices, parallel processing techniques allows Fog Machine to analyze data and answer complex questions quickly and efficiently.  Parallel processing over mesh-networks reduces the overall time to solve problems by taking advantage of shared resources (processors, memory, etc.).  The communication relies on a wifi or bluetooth chipset and is built on Apple's Multipeer Connectivity framework.

There are two demo apps provided. The first demo app is a simple text search that uses the [Knuth–Morris–Pratt](https://en.wikipedia.org/wiki/Knuth%E2%80%93Morris%E2%80%93Pratt_algorithm) string search algorithm to find a search term within a given text.  The second app calculates the [viewshed](https://en.wikipedia.org/wiki/Viewshed) of a position.  A viewshed is the geographical area that is visible from a location. It includes all surrounding points in line-of-sight with the location and excludes points that are beyond the horizon or obstructed by terrain and other features.  The viewshed app demonstrates the true power and flexibility of the Fog Machine framework.

Fog Machine was developed at the National Geospatial-Intelligence Agency (NGA) in collaboration with BIT Systems. The government has "unlimited rights" and is releasing this software to increase the impact of government investments by providing developers with the opportunity to take things in new directions. The software use, modification, and distribution rights are stipulated within the MIT license.

## Installation with CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C and Swift. You can install CocoaPods with the following command:

```bash
$ gem install cocoapods
```

#### Podfile

To integrate Fog Machine into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'

target 'TargetName' do
pod 'FogMachine', '~> 4.0.2'
end
```

Then, run the following command:

```bash
$ pod install
```

## Build from source

Pull down the latest source:
```bash
git clone git@github.com:ngageoint/fog-machine.git
```

Download the dependencies that Fog Machine needs from [CocoaPods](https://cocoapods.org/):   

```bash
pod cache clean --all
pod install
```

Launch xcode and smile, you're all done:
```bash
open FogMachine.xcworkspace
```

## Usage

The Fog Machine framework provides a simple lifecycle for your app to use.  After extending FMTool, you can immediately start running your tasks in parallel.

```swift
// What do I need help with?  How about saying hello?
public class HelloWorldTool : FMTool {
  public override func createWork(node:FMNode, nodeNumber:UInt, numberOfNodes:UInt) -> HelloWorldWork {
    return HelloWorldWork(nodeNumber: nodeNumber)
  }

  public override func processWork(node:FMNode, fromNode:FMNode, work: FMWork) -> HelloWorldResult {
    let helloWorldWork:HelloWorldWork = work as! HelloWorldWork
    print("Hello world, this is node \(helloWorldWork.nodeNumber).")
    return HelloWorldResult(didSayHello: true)
  }

  public override func mergeResults(node:FMNode, nodeToResult: [FMNode:FMResult]) -> Void {
    var totalNumberOfHellos:Int = 0
    for (n, result) in nodeToResult {
      let helloWorldResult = result as! HelloWorldResult
      if(helloWorldResult.didSayHello) {
        totalNumberOfHellos += 1
      }
    }
    print("Said hello \(totalNumberOfHellos) times.  It's a good day. :)")
  }
}


// Tell Fog Machine what we need help with
FogMachine.fogMachineInstance.setTool(HelloWorldTool())

// Look for friends/devices to help me
FogMachine.fogMachineInstance.startSearchForPeers()

// Run HelloWorldTool on all the nodes in the Fog Machine mesh-network and say hello to everyone!
FogMachine.fogMachineInstance.execute()
```

## Pros and Cons

Parallel processing over mesh-networks reduces the overall time to solve problems by taking advantage of shared resources (processors, memory, etc.).  There are pros and cons to using the Fog Machine framework, some of which are below.

#### Pros

* You can easily take advantage of the shared resources like processors, memory, and storage of all the devices in your network.  This can considerably increase performance.  The table below show how increasing the number of devices in the network decreases the overall time for the search app.

<table>
    <tr>
        <td># of devices</td>
        <td>1</td>
        <td>2</td>
        <td>3</td>
        <td>4</td>
    </tr>
    <tr>
        <td>demo app runtime in seconds</td>
        <td>42.5</td>
        <td>33.6</td>
        <td>32.7</td>
        <td>30.0</td>
    </tr>
</table>

* Works entirely disconnect.  The framework does not rely on any backend connection.  No need for LTE or Wi-Fi.
* At its core, the Fog Machine framework uses Apple's Multipeer Connectivity framework.  MPC is well supported across all iOS devices which means great interoperability within the iOS family.
* If, for whatever reason, a device in your network fails to process its piece of work, that piece of work will automatically get reprocessed elsewhere.  This reprocessing provides transparent flexibility in your network.
* Although not the primary focus of Fog Machine, the framework allows you to easily share information across devices as well.

#### Cons

* Communication relies on a wifi or bluetooth chipset and may not be reliable enough if your devices are not in close enough proximity to one another.  
* Introducing a considerably slower device to your network (relative to the other devices) could result in worse performance.  Consider a network with two iPhone 6s and one iPhone 4s.  If each processor has to process the same number of instructions, the two 6s could finish considerably faster than the 4s and then wait idly for the 4s to finish processing.  If this is a large concern in your situation, you can easily add logic to your tool's lifecycle to account for these types of discrepancies.
* The communication overhead between devices is based on the size of your FMWork and FMResult.  The size of these components are likely small, but in a case where it is necessary to send a very large amount of information between devices, the increase in communication time could exceed the decrease gained by parallel processing.  If this is the case, you will likely need to re-evaluate your design and determine whether Fog Machine is the right fit for your needs.
* A network is currently limited to 8 devices

## Requirements

Fog Machine requires iOS 9.0+.

## Pull Requests

If you'd like to contribute to this project, please make a pull request. We'll review the pull request and discuss the changes. All pull request contributions to this project will be released under the MIT license.

Software source code previously released under an open source license and then modified by NGA staff is considered a "joint work" (see 17 USC § 101); it is partially copyrighted, partially public domain, and as a whole is protected by the copyrights of the non-government authors and must be released according to the terms of the original open source license.

## Acknowledgements

Fog Machine makes use of the following open source projects:
- **PeerKit**  
*https://github.com/jpsim/PeerKit*
This product includes software licensed under the MIT License http://opensource.org/licenses/mit-license.php
- **SwiftEventBus**  
*https://github.com/cesarferreira/SwiftEventBus*
This product includes software licensed under the MIT License http://opensource.org/licenses/mit-license.php
