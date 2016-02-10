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
        self.mapView.delegate = self

        self.getHgtFiles()
        self.getTheMap()
        
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
        dataCell.textLabel!.text = self.pickerData[indexPath.row]
        return dataCell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.pickerData.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let currentCell = tableView.cellForRowAtIndexPath(indexPath)! as UITableViewCell
        let selectedHGTFile = currentCell.textLabel!.text!
        if let aTmpStr:String = selectedHGTFile {
            if !aTmpStr.isEmpty {
                self.hgtFilename = aTmpStr[aTmpStr.startIndex.advancedBy(0)...aTmpStr.startIndex.advancedBy(6)]
                mapView.removeAnnotations(mapView.annotations)
                self.hgtCoordinate = parseCoordinate(hgtFilename)
                let annotation = MKPointAnnotation()
                annotation.coordinate = self.hgtCoordinate
                annotation.title = "Delete " + hgtFilename + ".hgt" + "?"
                annotation.subtitle = "\(String(format:"%.4f", self.hgtCoordinate.latitude));\(String(format:"%.4f", self.hgtCoordinate.longitude))"
                mapView.addAnnotation(annotation)
                let latDelta: CLLocationDegrees = 10
                let lonDelta: CLLocationDegrees = 10
                let span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
                let region: MKCoordinateRegion = MKCoordinateRegionMake(self.hgtCoordinate, span)
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
        do {
            let fm = NSFileManager.defaultManager()
            let documentDirPath:NSURL =  try fm.URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
            let docDirItems = try! fm.contentsOfDirectoryAtPath(documentDirPath.path!)
            for docDirItem in docDirItems {
                if docDirItem.hasSuffix(".hgt") {
                    self.manageHgtDataArray(docDirItem, arrayAction: "add")
                    self.addRectBoundry(self.hgtCoordinate.latitude, longitude: self.hgtCoordinate.longitude)
                }
            }
        } catch let error as NSError  {
            print("Could get the HGT files: \(error.localizedDescription)")
        }
    }
    
    func manageHgtDataArray(docDirItem: String, arrayAction: String) {
        
        let hgFileName = NSURL(fileURLWithPath: docDirItem).URLByDeletingPathExtension?.lastPathComponent
        self.hgtCoordinate = self.parseCoordinate(hgFileName!)
        let tableCellItem = "\(docDirItem) (Lat:\(self.hgtCoordinate.latitude) Lng:\(self.hgtCoordinate.longitude))"
        
        if (!self.pickerData.contains(tableCellItem) && arrayAction == "add") {
            self.pickerData.append(tableCellItem)
        }
        if (self.pickerData.contains(tableCellItem) && arrayAction == "remove") {
            let index = self.pickerData.indexOf(tableCellItem)
            self.pickerData.removeAtIndex(index!)
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
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let defaultOverlay = MKPolygonRenderer()
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
        return defaultOverlay
    }
    
    func addRectBoundry(latitude: Double, longitude: Double) {
        var points = [
            CLLocationCoordinate2DMake(latitude, longitude),
            CLLocationCoordinate2DMake(latitude+1, longitude),
            CLLocationCoordinate2DMake(latitude+1, longitude+1),
            CLLocationCoordinate2DMake(latitude, longitude+1)
        ]
        polygonOverlay = MKPolygon(coordinates: &points, count: points.count)
        self.mapView.addOverlay(polygonOverlay)
    }
    
    func removeRectBoundry(latitude: Double, longitude: Double) {
        var points = [
            CLLocationCoordinate2DMake(latitude, longitude),
            CLLocationCoordinate2DMake(latitude+1, longitude),
            CLLocationCoordinate2DMake(latitude+1, longitude+1),
            CLLocationCoordinate2DMake(latitude, longitude+1)
        ]
        polygonOverlay = MKPolygon(coordinates: &points, count: points.count)
        self.mapView.removeOverlay(polygonOverlay)
    }
    
    func removeAllFromMap() {
        self.mapView.removeAnnotations(mapView.annotations)
        self.mapView.removeOverlays(mapView.overlays)
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        var view : MKAnnotationView! = nil
        let t: String = String(annotation.title)
        if (t.containsString("Download")) {
            let identifier = "downloadFile"
            view = self.mapViewCalloutAccessoryAction("Download", annotation: annotation, identifier: identifier)
        } else { //if (t.containsString("Delete")) {
            let identifier = "deleteFile"
            view = self.mapViewCalloutAccessoryAction("Delete", annotation: annotation, identifier: identifier)
        }
        return view
    }
    
    func mapViewCalloutAccessoryAction(calloutAction: String, annotation: MKAnnotation, identifier: String)-> MKAnnotationView? {
        var view : MKAnnotationView! = nil
        view = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
        if view == nil {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: -5, y: 5)
            
            let image = UIImage(named:calloutAction)
            let button = UIButton(type: UIButtonType.DetailDisclosure)
            button.setImage(image, forState: UIControlState.Normal)
            view!.leftCalloutAccessoryView = button as UIView
        }
         return view
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
       
        let annotation = view.annotation!
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
        lat = floor(lat)
        lng = floor(lng)
        
        let strFileName = (String(format:"%@%02d%@%03d%@", latPref, abs(Int(lat)), lonPref, abs(Int(lng)), ".hgt"))
        self.hgtCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        let strTableCellItem = "\(strFileName) (Lat:\(lat) Lng:\(lng))"
        
        if view.reuseIdentifier == "downloadFile" {
            self.initiateDownload(annotationView: view, tableCellItem2Add: strTableCellItem, hgtFileName: strFileName)
        } else if view.reuseIdentifier == "deleteFile" {
            self.initiateDelete(strFileName)
        }
    }
    
    func initiateDownload(annotationView view: MKAnnotationView, tableCellItem2Add: String, hgtFileName: String) {
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
                ActivityIndicator.show("Downloading..", disableUI: false)
                for srtmDataRegion in SRTM.SERVER_REGIONS {
                    if (!self.downloadComplete) {
                        let hgtFilePath: String = SRTM.DOWNLOAD_SERVER + srtmDataRegion + "/" + hgtFileName
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
        if (destinationPath.isEmpty || destinationPath.containsString("Error")) {
            let alertController = UIAlertController(title: "Download Error!!", message: "Data unavailable...Try later.", preferredStyle: .Alert)
            let ok = UIAlertAction(title: "OK", style: .Default, handler: {
                (action) -> Void in
            })
            ActivityIndicator.hide(success: false, animated: true)
            alertController.addAction(ok)
            presentViewController(alertController, animated: true, completion: nil)
        } else {
            dispatch_async(dispatch_get_main_queue()) {
                () -> Void in
                ActivityIndicator.hide(success: true, animated: true)
                //print(downloadedFilePath + "->Download Completed!!")
                let fileName = NSURL(fileURLWithPath: destinationPath).lastPathComponent!
                // add the downloaded file to the array of file names...
                self.manageHgtDataArray(fileName, arrayAction: "add")
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
        ActivityIndicator.hide(success: false, animated: true)
        alertController.addAction(ok)
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func handleLongPress(gestureReconizer: UILongPressGestureRecognizer) {
        if gestureReconizer.state != UIGestureRecognizerState.Ended {
            touchLocation = gestureReconizer.locationInView(mapView)
            let locationCoordinate = mapView.convertPoint(touchLocation,toCoordinateFromView: mapView)
            self.mapView.removeAnnotations(mapView.annotations)
            //print("handleLongPress at lat: \(locationCoordinate.latitude) long: \(locationCoordinate.longitude)")
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = locationCoordinate
            annotation.title = "Download?"
            //annotation.subtitle = "lat: \(String(format:"%.4f", locationCoordinate.latitude)) long: \(String(format:"%.4f", locationCoordinate.longitude))"
            annotation.subtitle = "\(String(format:"%.4f", locationCoordinate.latitude));\(String(format:"%.4f", locationCoordinate.longitude))"
            self.mapView.addAnnotation(annotation)
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
    
    func deleteFile(hgtFileName: String?) {
        let documentDirPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        if hgtFileName?.isEmpty == false {
            
            let filePath = "\(documentDirPath[0])/\(hgtFileName!)"
            if NSFileManager.defaultManager().fileExistsAtPath(filePath) {
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(filePath)
                    
                    // refresh the map and the table after the hgt file has been removed.
                    dispatch_async(dispatch_get_main_queue()) {
                        () -> Void in
                        let fileName = NSURL(fileURLWithPath: filePath).lastPathComponent!
                        // remove the file from the array of file names...
                        self.manageHgtDataArray(fileName, arrayAction: "remove")
                        // remove the rectangle boundary on the map for the dowloaded data
                        self.removeAllFromMap()
                        // find out if there is a way to remove a selected map overlay..
                        //self.removeRectBoundry(self.hgtCoordinate.latitude, longitude: self.hgtCoordinate.longitude)
                        // navigate the data folder and redraw the overlays from the data files..
                        self.getHgtFiles()
                        // refresh the table with the latest array data
                        self.refresh()
                    }
                } catch let error as NSError  {
                    print("Error occurred during file delete : \(error.localizedDescription)")
                }
            }
        }
    }
    
    func initiateDelete(hgtFileName: String?) {
        let alertController = UIAlertController(title: "Delete selected data File?", message: "", preferredStyle: .Alert)
        let ok = UIAlertAction(title: "OK", style: .Default, handler: {
            (action) -> Void in
            self.deleteFile(hgtFileName)
        })
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel) {
            (action) -> Void in
            print("Delete cancelled!")
        }
        alertController.addAction(ok)
        alertController.addAction(cancel)
        presentViewController(alertController, animated: true, completion: nil)
    }
}





