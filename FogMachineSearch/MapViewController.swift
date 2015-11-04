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

    let regionRadius: CLLocationDistance = 350

    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        
        ////////////
        //Testing purposes
        var elevationMatrix = [[Double]](count:10, repeatedValue:[Double](count:10, repeatedValue:1))
        let obsX = 3
        let obsY = 3
        let obsHeight = 3
        let viewRadius = 2
        print("Elevation Matrix")
        elevationMatrix[4][4] = 10 //causes top right of printed viewshed to be 0
        elevationMatrix[3][4] = 10 //causes 2nd, 3rd and 4th from top right to be 0
        
        let view = Viewshed()
        var viewshed:[[Double]] = view.viewshed(elevationMatrix, obsX: obsX, obsY: obsY, obsHeight: obsHeight, viewRadius: viewRadius)
        ////////////
        
        let initialLocation = CLLocation(latitude:  38.9815, longitude: -77.43892)
        centerMapOnLocation(initialLocation)
        
        
        let startLat = 38.97898180980364
        let startLon = -77.44147717649722
        var currLat = startLat
        var currLon = startLon
        let size = 0.001
        var countRow = 0
        var countCol = 0
        for row in viewshed.reverse() {
            currLon = startLon
            countCol = 0
            for _ in row { //column
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
            }
            currLat = currLat + size
            countRow++
        }
        
        
//        makeGridSquare(38.97898180980364, lon: -77.44147717649722, size: 0.001)
//        
//        var workSquare = [
//            CLLocationCoordinate2DMake(38.98459735040207, -77.44143600776995),
//            CLLocationCoordinate2DMake(38.97898180980364, -77.44147717649722),
//            CLLocationCoordinate2DMake(38.97887860210396, -77.43464032292945),
//            CLLocationCoordinate2DMake(38.9844280125545, -77.43440222562209),
//            CLLocationCoordinate2DMake(38.98459735040207, -77.44143600776995)
//        ]
//        
//        let workSquarePolygon: MKPolygon = MKPolygon(coordinates: &workSquare, count: workSquare.count)
//        mapView.addOverlay(workSquarePolygon)
        

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
