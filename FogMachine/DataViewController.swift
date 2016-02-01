//
//  DataViewController.swift
//  FogMachineSearch
//
//  Created by Ram Subramaniam on 1/25/16.
//  Copyright © 2016 NGA. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class DataViewController: UIViewController, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource,
MKMapViewDelegate, UIGestureRecognizerDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    
    var hgtCoordinate:CLLocationCoordinate2D!
    var pickerData: [String] = [String]()
    var hgtFilename = "N39W075"
    var hgt: Hgt!
    
    var hgtElevation:[[Int]]!
    var manager = CLLocationManager()
    var polygonOverlay:MKPolygon!
    var touchLocation: CGPoint!
    
    var managedContext: NSManagedObjectContext {
        return (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.tableView.backgroundColor = UIColor.clearColor();
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        mapView.delegate = self
        getHgtFileInfo()
        getTheMap()
        
        let lpgr = UILongPressGestureRecognizer(target: self, action:"handleLongPress:")
        lpgr.minimumPressDuration = 0.5
        lpgr.delaysTouchesBegan = true
        lpgr.delegate = self
        self.mapView.addGestureRecognizer(lpgr)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let dataCell = tableView.dequeueReusableCellWithIdentifier("dataCell", forIndexPath: indexPath)
        dataCell.textLabel!.text = pickerData[indexPath.row]
        return dataCell
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pickerData.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let currentCell = tableView.cellForRowAtIndexPath(indexPath)! as UITableViewCell
        let selectedHGTFile = currentCell.textLabel!.text!
        if let aTmpStr:String = selectedHGTFile {
            if !aTmpStr.isEmpty {
                hgtFilename = aTmpStr[aTmpStr.startIndex.advancedBy(0)...aTmpStr.startIndex.advancedBy(6)]
                mapView.removeAnnotations(mapView.annotations)
                self.hgtCoordinate = parseCoordinate(hgtFilename)
                let annotation = MKPointAnnotation()
                annotation.coordinate = hgtCoordinate
                annotation.title = hgtFilename
                annotation.subtitle = "lat: \(String(format:"%.4f", self.hgtCoordinate.latitude)) lng: \(String(format:"%.4f", self.hgtCoordinate.longitude))"
                mapView.addAnnotation(annotation)
                let latDelta: CLLocationDegrees = 10
                let lonDelta: CLLocationDegrees = 10
                let span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
                let region: MKCoordinateRegion = MKCoordinateRegionMake(hgtCoordinate, span)
                self.mapView.setRegion(region, animated: true)
            }
        }
    }
    
    func getTheMap() {
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func getHgtFileInfo() {
        let fm = NSFileManager.defaultManager()
        let path = NSBundle.mainBundle().resourcePath!
        
        do {
            let items = try fm.contentsOfDirectoryAtPath(path)
            for var item: String in items {
                if (item == "HGT") {
                    
                    let hgtFolder = path + "/HGT"
                    let hgtFiles = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(hgtFolder)
                    for var hgFileWithExt: String in hgtFiles {
                        let hgFileName = NSURL(fileURLWithPath: hgFileWithExt).URLByDeletingPathExtension?.lastPathComponent
                        if hgFileName != "README" {
                            self.hgtCoordinate = parseCoordinate(hgFileName!)
                            pickerData.append("\(hgFileWithExt) (Lat:\(self.hgtCoordinate.latitude) Lng:\(self.hgtCoordinate.longitude))")
                            addRectBoundry(hgtCoordinate.latitude, longitude: hgtCoordinate.longitude)
                        }
                    }
                    break
                }
            }
        } catch let error as NSError  {
            print("Could get the HGT files: \(error.userInfo)")
        }
    }
    
    // latitude and 105 degrees west longitude
    func parseCoordinate(filename : String) -> CLLocationCoordinate2D {
        
        let northSouth = filename.substringWithRange(Range<String.Index>(start: filename.startIndex,end: filename.startIndex.advancedBy(1)))
        let latitudeValue = filename.substringWithRange(Range<String.Index>(start: filename.startIndex.advancedBy(1),end: filename.startIndex.advancedBy(3)))
        let westEast = filename.substringWithRange(Range<String.Index>(start: filename.startIndex.advancedBy(3),end: filename.startIndex.advancedBy(4)))
        let longitudeValue = filename.substringWithRange(Range<String.Index>(start: filename.startIndex.advancedBy(4),end: filename.endIndex))
        
        var latitude:Double = Double(latitudeValue)!
        var longitude:Double = Double(longitudeValue)!
        
        if (northSouth.uppercaseString == "S") {
            latitude = latitude * -1.0
        }
        
        if (westEast.uppercaseString == "W") {
            longitude = longitude * -1.0
        }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        if overlay is MKPolygon {
            let polygonView = MKPolygonRenderer(overlay: overlay)
            polygonView.fillColor = UIColor.redColor().colorWithAlphaComponent(0.08)
            polygonView.strokeColor = UIColor.redColor().colorWithAlphaComponent(0.5)
            polygonView.lineWidth = 0.4
            return polygonView
        }
        if overlay is MKPolyline {
            let polylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRenderer.strokeColor = UIColor.blackColor()
            polylineRenderer.lineWidth = 0.4
            return polylineRenderer
        }
        return nil
    }
    
    func addRectBoundry(latitude: Double, longitude: Double) {
        var points = [
            CLLocationCoordinate2DMake(latitude-1, longitude),
            CLLocationCoordinate2DMake(latitude-1, longitude-1),
            CLLocationCoordinate2DMake(latitude, longitude-1),
            CLLocationCoordinate2DMake(latitude, longitude)
        ]
        polygonOverlay = MKPolygon(coordinates: &points, count: points.count)
        mapView.addOverlay(polygonOverlay)
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        var view : MKAnnotationView! = nil
        //print("annotation.title \(annotation.title)")
        let t: String = String(annotation.title)
        if (t.containsString("Download")) {
            let identifier = "greenPin"
            view = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
            if view == nil {
                _ = mapView.convertPoint(touchLocation,toCoordinateFromView: mapView)
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = true
                view.calloutOffset = CGPoint(x: -5, y: 5)
                let image = UIImage(named:"Download")
                let button = UIButton(type: UIButtonType.DetailDisclosure)
                button.setImage(image, forState: UIControlState.Normal)
                view!.leftCalloutAccessoryView = button as UIView
            }
        }
        return view
    }

    func handleLongPress(gestureReconizer: UILongPressGestureRecognizer) {
        if gestureReconizer.state != UIGestureRecognizerState.Ended {
            touchLocation = gestureReconizer.locationInView(mapView)
            let locationCoordinate = mapView.convertPoint(touchLocation,toCoordinateFromView: mapView)
            mapView.removeAnnotations(mapView.annotations)
      
            let annotation = MKPointAnnotation()
            annotation.coordinate = locationCoordinate
            annotation.title = "Download?"
            annotation.subtitle = "lat: \(String(format:"%.4f", locationCoordinate.latitude)) long: \(String(format:"%.4f", locationCoordinate.longitude))"
            mapView.addAnnotation(annotation)
            let latDelta: CLLocationDegrees = 10
            let lonDelta: CLLocationDegrees = 10
            let span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
            let region: MKCoordinateRegion = MKCoordinateRegionMake(locationCoordinate, span)
            self.mapView.setRegion(region, animated: true)
            return
        }
        if gestureReconizer.state != UIGestureRecognizerState.Began {
            return
        }
    }
}

