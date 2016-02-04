//
//  DataViewController.swift
//  FogMachineSearch
//
//  Created by Ram Subramaniam on 1/25/16.
//  Copyright © 2016 NGA. All rights reserved.
//

import UIKit
import MapKit

class DataViewController: UIViewController, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource,
MKMapViewDelegate, UIGestureRecognizerDelegate, CLLocationManagerDelegate, HgtDownloadMgrDelegate {
    
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
    var downloadComplete: Bool = false
       
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.tableView.backgroundColor = UIColor.clearColor();
        self.tableView.delegate = self
        self.tableView.dataSource = self
        mapView.delegate = self

        getHgtFiles()
        getTheMap()
        
        let lpgr = UILongPressGestureRecognizer(target: self, action:"handleLongPress:")
        lpgr.minimumPressDuration = 0.5
        lpgr.delaysTouchesBegan = true
        lpgr.delegate = self
        self.mapView.addGestureRecognizer(lpgr)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
    
    func refresh() {
        self.tableView?.reloadData()
    }

    func getTheMap() {
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func getHgtFiles() {
        //print("Picker Data: \(pickerData)")
        do {
            let fm = NSFileManager.defaultManager()
            let documentDirPath:NSURL =  try! fm.URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
            let docDirItems = try! fm.contentsOfDirectoryAtPath(documentDirPath.path!)
            for var docDirItem in docDirItems {
                if docDirItem.hasSuffix(".hgt") {
                    manageHgtDataArray(docDirItem)
                    self.addRectBoundry(self.hgtCoordinate.latitude, longitude: self.hgtCoordinate.longitude)
                }
            }
        } catch let error as NSError  {
            print("Could get the HGT files: \(error.localizedDescription)")
        }
    }
    
    func manageHgtDataArray(docDirItem: String) {
        let hgFileName = NSURL(fileURLWithPath: docDirItem).URLByDeletingPathExtension?.lastPathComponent
        self.hgtCoordinate = self.parseCoordinate(hgFileName!)
        let tableCellItem = "\(docDirItem) (Lat:\(self.hgtCoordinate.latitude) Lng:\(self.hgtCoordinate.longitude))"
        
        if (!pickerData.contains(tableCellItem)) {
            self.pickerData.append(tableCellItem)
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
            polygonView.fillColor = UIColor.yellowColor().colorWithAlphaComponent(0.5) //UIColor.yellowColor().colorWithAlphaComponent(0.08)
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
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        //print("*** Download Map data *** ")
        //let locationCoordinate = mapView.convertPoint(touchLocation,toCoordinateFromView: mapView)
        //print("mapView at lat: \(locationCoordinate.latitude) long: \(locationCoordinate.longitude)")
        let annotation = view.annotation!
        let annotName = annotation.title
        let annotLatLng = annotation.subtitle
        
        let latLng = annotLatLng!!.componentsSeparatedByString(";") // added the ';' delimeter in the annotation subtitle in the handleLongPress
        var lat: Double! = Double(latLng[0])
        var lng: Double! = Double(latLng[1])
        
        var latPref = "N"
        if (lat < 0) {
            latPref = "S"
        }
        var lonPref = "E"
        if (lng < 0) {
            lonPref = "W"
        }
        // round the lat & long to the closest integer value..
        lat = round(lat)
        lng = round(lng)
        
        let hgtFileName = (String(format:"%@%02d%@%03d%@", latPref, abs(Int(lat)), lonPref, abs(Int(lng)), ".hgt"))
        let tableCellItem2Add = "\(hgtFileName) (Lat:\(lat) Lng:\(lng))"

        // check if the data already downloaded and exists in the table..
        // don't download if its there already
        if (pickerData.contains(tableCellItem2Add)) {
            let alertController = UIAlertController(title: hgtFileName, message: "File Already Exists..", preferredStyle: .Alert)
            let ok = UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
            })
            alertController.addAction(ok)
            presentViewController(alertController, animated: true, completion: nil)
        } else{
            self.downloadComplete = false
            let alertController = UIAlertController(title: hgtFileName, message: "Download this data File?", preferredStyle: .Alert)
            let ok = UIAlertAction(title: "OK", style: .Default, handler: {
                (action) -> Void in
                for var srtmDataRegion in SRTM.SERVER_REGIONS {
                    if (!self.downloadComplete) {
                        let hgtFilePath: String = SRTM.DOWNLOAD_SERVER + srtmDataRegion + "/" + hgtFileName
                        //print("HGT Data File Path: " + hgtFilePath)
                        let url = NSURL(string: hgtFilePath)
                        let hgtDownloadMgr = HgtDownloadMgr()
                        hgtDownloadMgr.delegate = self
                        hgtDownloadMgr.downloadHgtFile(url!)
                    }
                }
            })
            let cancel = UIAlertAction(title: "Cancel", style: .Cancel) {
                (action) -> Void in
                print("Download cancelled!")
            }
            alertController.addAction(ok)
            alertController.addAction(cancel)
            presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    func didReceiveResponse(destinationPath: String) {
        downloadComplete = true
        //print("Download Completed!! \t\(destinationPath)")
        if (destinationPath.isEmpty || destinationPath.containsString("Error")) {
            let alertController = UIAlertController(title: "Download Error!!", message: "Data unavailable...Try later.", preferredStyle: .Alert)
            let ok = UIAlertAction(title: "OK", style: .Default, handler: {
                (action) -> Void in
            })
            alertController.addAction(ok)
            presentViewController(alertController, animated: true, completion: nil)
        } else {
            dispatch_async(dispatch_get_main_queue()) {
                () -> Void in
                //print(downloadedFilePath + "->Download Completed!!")
                let fileName = NSURL(fileURLWithPath: destinationPath).lastPathComponent!
                // add the downloaded file to the array of file names...
                self.manageHgtDataArray (fileName)
                // draw the rectangle boundary on the map for the dowloaded data
                self.addRectBoundry(self.hgtCoordinate.latitude, longitude: self.hgtCoordinate.longitude)
                // refresh the table with the latest array data
                self.refresh()
            }
        }
    }
    func didFailToReceieveResponse(error: String) {
        let alertController = UIAlertController(title: "Download Error!!", message: "Data unavailable...Try later.", preferredStyle: .Alert)
        let ok = UIAlertAction(title: "OK", style: .Default, handler: {
            (action) -> Void in
        })
        alertController.addAction(ok)
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func handleLongPress(gestureReconizer: UILongPressGestureRecognizer) {
        if gestureReconizer.state != UIGestureRecognizerState.Ended {
            touchLocation = gestureReconizer.locationInView(mapView)
            let locationCoordinate = mapView.convertPoint(touchLocation,toCoordinateFromView: mapView)
            mapView.removeAnnotations(mapView.annotations)
            //print("handleLongPress at lat: \(locationCoordinate.latitude) long: \(locationCoordinate.longitude)")
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = locationCoordinate
            annotation.title = "Download?"
            //annotation.subtitle = "lat: \(String(format:"%.4f", locationCoordinate.latitude)) long: \(String(format:"%.4f", locationCoordinate.longitude))"
            annotation.subtitle = "\(String(format:"%.4f", locationCoordinate.latitude));\(String(format:"%.4f", locationCoordinate.longitude))"
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


