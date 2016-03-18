//
//  MetricSingleDevice.swift
//  FogViewshed
//
//  Created by Chris Wasko on 3/18/16.
//  Copyright © 2016 NGA. All rights reserved.
//

import Foundation


class MetricSingleDevice {
    
    
    
    var viewshedPalette: ViewshedPalette!
    
    var metricsOutput: String!
    var startTime: CFAbsoluteTime!//UInt64!//CFAbsoluteTime!
    var elapsedTime: CFAbsoluteTime!
    
    let defaultHgtFilename = "N39W077"
    
    
    // MARK: Metrics
    
    
    func initiateMetricsGathering(algorithm: ViewshedAlgorithm) {
        var metricGroup = dispatch_group_create()
        
        dispatch_group_enter(metricGroup)
        self.gatherMetrics(false, metricGroup: metricGroup, algorithm: algorithm)
        
        dispatch_group_notify(metricGroup, dispatch_get_main_queue()) {
            metricGroup = dispatch_group_create()
            
            dispatch_group_enter(metricGroup)
            self.gatherMetrics(true, metricGroup: metricGroup, algorithm: algorithm)
            
            dispatch_group_notify(metricGroup, dispatch_get_main_queue()) {
                print("All Done!")
            }
        }
    }
    
    
    func gatherMetrics(randomData: Bool, metricGroup: dispatch_group_t, algorithm: ViewshedAlgorithm) {
        metricsOutput = ""
        
        self.printOut("Metrics Report.")
        var viewshedGroup = dispatch_group_create()
        self.runComparison(2, viewshedGroup: viewshedGroup, randomData: randomData, algorithm: algorithm)
        
        dispatch_group_notify(viewshedGroup, dispatch_get_main_queue()) {
            viewshedGroup = dispatch_group_create()
            self.runComparison(4, viewshedGroup: viewshedGroup, randomData: randomData, algorithm: algorithm)
            
            dispatch_group_notify(viewshedGroup, dispatch_get_main_queue()) {
                viewshedGroup = dispatch_group_create()
                self.runComparison(8, viewshedGroup: viewshedGroup, randomData: randomData, algorithm: algorithm)
                
                dispatch_group_notify(viewshedGroup, dispatch_get_main_queue()) {
                    viewshedGroup = dispatch_group_create()
                    self.runComparison(16, viewshedGroup: viewshedGroup, randomData: randomData, algorithm: algorithm)
                    
                    dispatch_group_notify(viewshedGroup, dispatch_get_main_queue()) {
                        print("\nmetricsOutput\n\n\n\(self.metricsOutput)")
                        dispatch_group_leave(metricGroup)
                    }
                }
            }
        }
        
    }
    
    
    func runComparison(numObservers: Int, viewshedGroup: dispatch_group_t, randomData: Bool, algorithm: ViewshedAlgorithm){
        
        var observers: [Observer] = []
        var xCoord:Int
        var yCoord:Int
        var elevation:Int
        var radius:Int
        let defaultHgt = Hgt(filename: defaultHgtFilename)
        
        self.printOut("Metrics Started for \(numObservers) observer(s).")
        if randomData {
            self.printOut("Using random data.")
        } else {
            self.printOut("Using pattern data from top left to bottom right.")
        }
        
        for count in 1...numObservers {
            let name = "Observer " + String(count)
            
            if randomData {
                //Random Data
                xCoord = Int(arc4random_uniform(700) + 200)
                yCoord = Int(arc4random_uniform(700) + 200)
                elevation = Int(arc4random_uniform(100) + 1)
                radius = Int(arc4random_uniform(600) + 1)
            } else {
                //Pattern Data - Right Diagonal
                xCoord = count * 74
                yCoord = count * 74
                elevation = count + 5
                radius = count + 100 //If the radius grows substantially larger then the parallel threads will finish sequentially
            }
            
            let observer = Observer(name: name, xCoord: xCoord, yCoord: yCoord, elevation: elevation, radius: radius, coordinate: defaultHgt.getCoordinate())
            self.printOut("\tObserver \(name): x: \(xCoord)\ty: \(yCoord)\theight: \(elevation)\tradius: \(radius)")
            observers.append(observer)
        }
        
        //Starting serial before the parallel so the parallel will not be running when the serial runs
        self.printOut("\nStarting Serial Viewshed")
        
        self.startTimer()
        for obs in observers {
            self.performSerialViewshed(obs, algorithm: algorithm)
        }
        self.stopTimer()
        //self.removeAllFromMap()
        
        self.printOut("Serial Viewshed Total Time: \(self.elapsedTime)")
        self.printOut("\nStarting Parallel Viewshed")
        
        self.startTimer()
        for obsP in observers {
            self.performParallelViewshed(obsP, algorithm: algorithm, viewshedGroup: viewshedGroup)
        }
        
        dispatch_group_notify(viewshedGroup, dispatch_get_main_queue()) {
            self.stopTimer()
            self.printOut("Parallel Viewshed Total Time: \(self.elapsedTime)")
            print("Parallel Viewshed Total Time: \(self.elapsedTime)")
            self.clearTimer()
            self.printOut("Metrics Finished for \(numObservers) Observer(s).\n")
        }
        
    }
    
    
    func performParallelViewshed(observer: Observer, algorithm: ViewshedAlgorithm, viewshedGroup: dispatch_group_t) {
        
        dispatch_group_enter(viewshedGroup)
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
            
            self.printOut("Starting Parallel Viewshed Processing on \(observer.name).")
            
            if (algorithm == ViewshedAlgorithm.FranklinRay) {
                let obsViewshed = ViewshedFog(elevation: self.viewshedPalette.getHgtElevation(), observer: observer, numberOfQuadrants: 1, whichQuadrant: 1)
                self.viewshedPalette.viewshedResults = obsViewshed.viewshedParallel()
            } else if (algorithm == ViewshedAlgorithm.VanKreveld) {
                // running Van Kreveld viewshed.
                let kreveld: KreveldViewshed = KreveldViewshed()
                let observerPoints: ElevationPoint = ElevationPoint (xCoord:observer.xCoord, yCoord: observer.yCoord)
                self.viewshedPalette.viewshedResults = kreveld.parallelKreveld(self.viewshedPalette.getHgtElevation(), observPt: observerPoints, radius: observer.getViewshedSrtm3Radius(), numOfPeers: 1, quadrant2Calc: 0)
            }
            dispatch_async(dispatch_get_main_queue()) {
                
                self.printOut("\tFinished Viewshed Processing on \(observer.name).")
                
                //self.pinObserverLocation(observer)
                //let viewshedOverlay = self.viewshedPalette.getViewshedOverlay()
                //self.mapView.addOverlay(viewshedOverlay)
                
                dispatch_group_leave(viewshedGroup)
            }
        }
    }
    
    
    func performSerialViewshed(observer: Observer, algorithm: ViewshedAlgorithm) {
        
        self.printOut("Starting Serial Viewshed Processing on \(observer.name).")
        
        if (algorithm == ViewshedAlgorithm.FranklinRay) {
            let obsViewshed = ViewshedFog(elevation: self.viewshedPalette.getHgtElevation(), observer: observer, numberOfQuadrants: 1, whichQuadrant: 1)
            self.viewshedPalette.viewshedResults = obsViewshed.viewshedParallel()
        } else if (algorithm == ViewshedAlgorithm.VanKreveld) {
            let kreveld: KreveldViewshed = KreveldViewshed()
            //let demObj: DemData = DemData(demMatrix: self.viewshedPalette.getHgtElevation())
            // observer.radius = 200 // default radius 100
            // set the added observer height
            let observerPoints: ElevationPoint = ElevationPoint (xCoord:observer.xCoord, yCoord: observer.yCoord, h: observer.elevation)
            self.viewshedPalette.viewshedResults = kreveld.parallelKreveld(self.viewshedPalette.getHgtElevation(), observPt: observerPoints, radius: observer.getViewshedSrtm3Radius(), numOfPeers: 1, quadrant2Calc: 1)
            //obsResults = kreveld.calculateViewshed(demObj, observPt: observerPoints, radius: observer.radius, numQuadrants: 0, quadrant2Calc: 0)
        }
        
        self.printOut("\tFinished Viewshed Processing on \(observer.name).")
        
        //self.pinObserverLocation(observer)
        
        //let viewshedOverlay = self.viewshedPalette.getViewshedOverlay()
        dispatch_async(dispatch_get_main_queue()) {
            //self.mapView.addOverlay(viewshedOverlay)
        }
    }
    
    
    func startParallel(algorithm: ViewshedAlgorithm) {
        
        let defaultHgt = Hgt(filename: defaultHgtFilename)
        let viewshedGroup = dispatch_group_create()
        self.startTimer()
        //  dispatch_apply(8, dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) { index in
        // let count = Int(index + 1)
        for count in 1...8 {
            
            let observer = Observer(name: String(count), xCoord: count * 100, yCoord: count * 100, elevation: 20, radius: 600, coordinate: defaultHgt.getCoordinate())
            
            self.performParallelViewshed(observer, algorithm: algorithm, viewshedGroup: viewshedGroup)
        }
        
        dispatch_group_notify(viewshedGroup, dispatch_get_main_queue()) {
            self.stopTimer()
        }
    }
    
    
    func startSerial(algorithm: ViewshedAlgorithm) {
        
        let defaultHgt = Hgt(filename: defaultHgtFilename)
        self.startTimer()
        
        for count in 1...8 {
            //let observer = Observer(name: String(count), x: count * 100, y: count * 100, height: 20, radius: options.radius, coordinate: self.hgtCoordinate)
            let observer = Observer(name: String(count), xCoord: 600, yCoord: 600, elevation: 20, radius: 600, coordinate: defaultHgt.getCoordinate())
            //let observer = Observer(name: String(count), x: 8 * 100, y: 8 * 100, height: 20, radius: options.radius, coordinate:self.hgtCoordinate)
            self.performSerialViewshed(observer, algorithm: algorithm)
        }
        
        self.stopTimer()
    }
    
    
    // MARK: Timer
    
    
    func startTimer() {
        startTime = CFAbsoluteTimeGetCurrent()
        //startParallelTimer = mach_absolute_time()
    }
    
    
    func stopTimer(toPrint: Bool=false, observer: String="") -> CFAbsoluteTime {
        elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
        self.printOut("Stop Time: " + String(format: "%.6f", elapsedTime))
        //let elapsedTime = mach_absolute_time() - startParallelTimer
        if toPrint {
            self.printOut("Observer \(observer):\t\(elapsedTime)")
        }
        return elapsedTime
    }
    
    
    func clearTimer() {
        startTime = 0
        elapsedTime = 0
    }
    
    
    // MARK: Single
    
    
    func singleRandomObserver() -> Observer {
        let name = String(arc4random_uniform(10000) + 1)
        let xCoord = Int(arc4random_uniform(700) + 200)
        let yCoord = Int(arc4random_uniform(700) + 200)
        let defaultHgt = Hgt(filename: defaultHgtFilename)
        return Observer(name: name, xCoord: xCoord, yCoord: yCoord, elevation: 20, radius: 300, coordinate: defaultHgt.getCoordinate())
    }
    
    
    func singleViewshed(algorithm: ViewshedAlgorithm) {
        self.performSerialViewshed(singleRandomObserver(), algorithm: algorithm)
    }
    
    
    // MARK: Logging/Printing
    
    
    func printOut(output: String) {
        dispatch_async(dispatch_get_main_queue()) {
            let range = NSMakeRange(0, (output as NSString).length)
            if let regex = try? NSRegularExpression(pattern: "😺[0-9]*", options: .CaseInsensitive) {
                let printableOutput = regex.stringByReplacingMatchesInString(output, options: .WithTransparentBounds, range: range, withTemplate: "")
                //Can easily change this to print out to a file without modifying the rest of the code.
                print(printableOutput)
                self.metricsOutput = self.metricsOutput + "\n" + printableOutput
                //self.logBox.text = self.logBox.text + "\n" + printableOutput
            }
        }
    }
    
    
}