//
//  MapViewController.swift
//  FogMachineSearch
//
//  Created by Chris Wasko on 11/4/15.
//  Copyright © 2015 NGA. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!

    let regionRadius: CLLocationDistance = 100000

    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        
        let initialLocation = CLLocation(latitude:  38.0, longitude: -77.0)
        centerMapOnLocation(initialLocation)
      
        print("Starting Viewshed...please wait patiently.")
        
        let hgtElevationMatrix:[[Double]] = readHgt()
        
        

        //Testing purposes
        //var elevationMatrix = [[Double]](count:10, repeatedValue:[Double](count:10, repeatedValue:1))
        let obsX = 600
        let obsY = 600
        let obsHeight = 3
        let viewRadius = 599
        //print("Elevation Matrix")
        //elevationMatrix[4][4] = 10 //causes top right of printed viewshed to be 0
        //elevationMatrix[3][4] = 10 //causes 2nd, 3rd and 4th from top right to be 0
        
        let view = Viewshed()
        var viewshed:[[Double]] = view.viewshed(hgtElevationMatrix, obsX: obsX, obsY: obsY, obsHeight: obsHeight, viewRadius: viewRadius)

        
        print("Finished Viewshed calculation...rendering a bunch of squares")
  
        
        let startLat = 38.0//.97898180980364
        let startLon = -77.0//.44147717649722
        var currLat = startLat
        var currLon = startLon
        let size = 0.00083
        var countRow = 0
        var countCol = 0
        var count = 0 //hardcoded for testing
        var iterator = 0 //hardcoded for testing
//        for row in viewshed.reverse() {
        while ( iterator < 20) {
            currLon = startLon
            countCol = 0
            //for _ in row { //column
            count = 0
            while ( count < 20) {
                if viewshed[countRow][countCol] == -1 {
                    makeCell(UIColor.purpleColor(), lat: currLat, lon: currLon, size: size)
                } else if viewshed[countRow][countCol] == 1 {
                    makeCell(UIColor.greenColor(), lat: currLat, lon: currLon, size: size)
                } else if viewshed[countRow][countCol] == 0 {
                    makeCell(UIColor.redColor(), lat: currLat, lon: currLon, size: size)
                }
                
                //makeGridSquare(currLat, lon: currLon, size: size)

                currLon = currLon + size
                countCol++
                count++
            }
           // }
            currLat = currLat + size
            countRow++
            iterator++
            print("Rendered row \(countRow)")
        }
        
        print("Bunch of squares renderation complete!")
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    func readHgt() -> [[Double]] {
        
        let path = NSBundle.mainBundle().pathForResource("N38W077", ofType: "hgt")
        let url = NSURL(fileURLWithPath: path!)
        let data = NSData(contentsOfURL: url)!
        
        
//        
//        //let randomData = generateRandomData(256 * 1024)
//        let stream = NSInputStream(data: data)
//        stream.open() // IMPORTANT
//        var readBuffer = Array<UInt8>(count: 1200 * 1200, repeatedValue: 0)
//        var totalBytesRead = 0
//        while (totalBytesRead < data.length)
//        {
//            let numberOfBytesRead = stream.read(&readBuffer, maxLength: readBuffer.count)
//            // Do something with the data
//            totalBytesRead += numberOfBytesRead
//        }
        

        var elevationMatrix = [[Double]](count:1200, repeatedValue:[Double](count:1200, repeatedValue:0))

        
        let dataRange = NSRange(location: 0, length: 2884802)//1200 * 1200)
        var handNumbers = [Int8](count: 2884802, repeatedValue: 0)
        data.getBytes(&handNumbers, range: dataRange)
        
        
        var row = 0
        var column = 0
        for (var cell = 1; cell < 2884802; cell+=2) {
            elevationMatrix[row][column] = Double(handNumbers[cell])
            
            column++
            
            if column >= 1200 {
                column = 0
                row++
            }
            
            if row >= 1200 {
                break
            }
        }
        
        return elevationMatrix
    }
    
    
    func generateRandomData(count:Int) -> NSData
    {
        var array = Array<UInt8>(count: count, repeatedValue: 0)
        
        arc4random_buf(&array, count)
        return NSData(bytes: array, length: count)
    }
    
    
    
    
    func makeCell(color: UIColor, lat: Double, lon: Double, size: Double) {
        let lowerLeftLat = lat
        let lowerRightLat = lat
        let upperRightLat = lat + size
        let upperLeftLat = lat + size
        
        let lowerLeftLon = lon
        let lowerRightLon = lon + size
        let upperRightLon = lon  + size
        let upperLeftLon = lon
        
        
        var square = [
            CLLocationCoordinate2DMake(lowerLeftLat, lowerLeftLon),
            CLLocationCoordinate2DMake(lowerRightLat, lowerRightLon),
            CLLocationCoordinate2DMake(upperRightLat, upperRightLon),
            CLLocationCoordinate2DMake(upperLeftLat, upperLeftLon),
            CLLocationCoordinate2DMake(lowerLeftLat, lowerLeftLon)
        ]
        let squarePolygon = Cell(coordinates: &square, count: square.count)
        squarePolygon.color = color
        //let squarePolygon: MKPolygon = MKPolygon(coordinates: &square, count: square.count)
        mapView.addOverlay(squarePolygon)

    }
    
    func makeGridSquare(lat: Double, lon: Double, size: Double) {
        
        let lowerLeftLat = lat
        let lowerRightLat = lat
        let upperRightLat = lat + size
        let upperLeftLat = lat + size
        
        let lowerLeftLon = lon
        let lowerRightLon = lon + size
        let upperRightLon = lon  + size
        let upperLeftLon = lon
        
        
        var square = [
            CLLocationCoordinate2DMake(lowerLeftLat, lowerLeftLon),
            CLLocationCoordinate2DMake(lowerRightLat, lowerRightLon),
            CLLocationCoordinate2DMake(upperRightLat, upperRightLon),
            CLLocationCoordinate2DMake(upperLeftLat, upperLeftLon),
            CLLocationCoordinate2DMake(lowerLeftLat, lowerLeftLon)
        ]
        
        let squarePolygon: MKPolygon = MKPolygon(coordinates: &square, count: square.count)
        mapView.addOverlay(squarePolygon)
    }
    
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        var polygonView:MKPolygonRenderer? = nil
//        if overlay is MKPolygon {
//            polygonView = MKPolygonRenderer(overlay: overlay)
//            polygonView!.lineWidth = 0.1
//            polygonView!.strokeColor = UIColor.grayColor()
//            polygonView!.fillColor = UIColor.grayColor().colorWithAlphaComponent(0.3)
//        } else
        if overlay is Cell {
            polygonView = MKPolygonRenderer(overlay: overlay)
            polygonView!.lineWidth = 0.1
            let color:UIColor = (overlay as! Cell).color!
            polygonView!.strokeColor = color
            polygonView!.fillColor = color.colorWithAlphaComponent(0.3)
        }

        return polygonView!
    }
    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
