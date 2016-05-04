import UIKit
import MapKit

class DataViewController: UIViewController, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate, UIGestureRecognizerDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var gpsButton: UIButton!
    
    var hgtCoordinate:CLLocationCoordinate2D!
    var pickerData: [String] = [String]()
    var hgtFilename:String = String()
    var locationManager: CLLocationManager!
    var isInitialAuthorizationCheck = false
    let zoomLevelDegrees:Double = 5
    let arrowPressedImg = UIImage(named: "ArrowPressed")! as UIImage
    let arrowImg = UIImage(named: "Arrow")! as UIImage
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.tableView.backgroundColor = UIColor.clearColor();
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.mapView.delegate = self
        
//        let lpgr = UILongPressGestureRecognizer(target: self, action:#selector(DataViewController.handleLongPress(_:)))
//        lpgr.minimumPressDuration = 0.5
//        lpgr.delaysTouchesBegan = true
//        lpgr.delegate = self
//        self.mapView.addGestureRecognizer(lpgr)
        
        if (self.locationManager == nil) {
            self.locationManager = CLLocationManager()
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.delegate = self
        }
        let status = CLLocationManager.authorizationStatus()
        if (status == .NotDetermined || status == .Denied || status == .Restricted)  {
            // present an alert indicating location authorization required
            // and offer to take the user to Settings for the app via
            self.locationManager.requestWhenInUseAuthorization()
            self.mapView.tintColor = UIColor.blueColor()
        }
        gpsButton.setImage(arrowPressedImg, forState: UIControlState.Normal)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // redraw
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func focusToCurrentLocation(sender: AnyObject) {
        gpsButton.setImage(arrowPressedImg, forState: UIControlState.Normal)
        
        if let coordinate = mapView.userLocation.location?.coordinate {
            // Get the span that the mapView is set to by the user.
            let span = self.mapView.region.span
            // Now setup the region based on the lat/lon and retain the span that already exists.
            let region = MKCoordinateRegion(center: coordinate, span: span)
            //Center the view with some animation.
            self.mapView.setRegion(region, animated: true)
        }
    }
    
    func mapView(mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        let view = self.mapView.subviews[0]
        //  Look through gesture recognizers to determine whether this region change is from user interaction
        if let gestureRecognizers = view.gestureRecognizers {
            for recognizer in gestureRecognizers {
                if( recognizer.state == UIGestureRecognizerState.Began || recognizer.state == UIGestureRecognizerState.Ended ) {
                    gpsButton.setImage(arrowImg, forState: UIControlState.Normal)
                }
            }
        }
    }
    
    // MARK: - Location Delegate Methods
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if (status == .AuthorizedWhenInUse || status == .AuthorizedAlways) {
            self.locationManager.startUpdatingLocation()
            self.isInitialAuthorizationCheck = true
            self.mapView.showsUserLocation = true
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if (self.isInitialAuthorizationCheck) {
            //self.pinDownloadeAnnotation(locations.last!)
            let title = "Download Current Location?"
            self.pinAnnotation(title, coordinate: locations.last!.coordinate)
            self.locationManager.stopUpdatingLocation()
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Error: " + error.localizedDescription)
    }
   
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let dataCell = tableView.dequeueReusableCellWithIdentifier("dataCell", forIndexPath: indexPath)
        dataCell.textLabel!.text = self.pickerData[indexPath.row]
        return dataCell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.pickerData.count
    }
    
    func refresh() {
        self.tableView?.reloadData()
    }
    
    func pinAnnotation(title: String, subtitle: String = "", coordinate: CLLocationCoordinate2D) {
        // remove all the annotations on the map
        self.mapView.removeAnnotations(mapView.annotations)
        
        // Get the span that the mapView is set to by the user.
        let span = self.mapView.region.span
        // Now setup the region based on the lat/lon and retain the span that already exists.
        let region = MKCoordinateRegion(center: coordinate, span: span)
        //Center the view with some animation.
        self.mapView.setRegion(region, animated: true)
        
        let pointAnnotation:MKPointAnnotation = MKPointAnnotation()
        pointAnnotation.coordinate = coordinate
        pointAnnotation.title = title
        pointAnnotation.subtitle = subtitle
        self.mapView.addAnnotation(pointAnnotation)
    }

    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let defaultOverlay = MKPolygonRenderer()
        if overlay is MKPolygon {
            let polygonView = MKPolygonRenderer(overlay: overlay)
            polygonView.lineWidth = 0.5
            polygonView.fillColor = UIColor.yellowColor().colorWithAlphaComponent(0.4)
            polygonView.strokeColor = UIColor.redColor().colorWithAlphaComponent(0.6)

            return polygonView
        }
        return defaultOverlay
    }
    
    
    func removeAllFromMap() {
        self.mapView.removeAnnotations(mapView.annotations)
        self.mapView.removeOverlays(mapView.overlays)
    }

    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        // if the annotation is dragged to a different location, handle it
        if newState == MKAnnotationViewDragState.Ending {
            //let droppedAt = view.annotation?.coordinate
            let annotation = view.annotation!
            let title:String = ((view.annotation?.title)!)!
            self.pinAnnotation(title, coordinate: annotation.coordinate)
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        var view : MKAnnotationView! = nil
        let t: String = String(annotation.title)
        if (annotation is MKUserLocation) {
            //if annotation is not an MKPointAnnotation (eg. MKUserLocation),
            //return nil so map draws default view for it (eg. blue dot)...
            //let identifier = "downloadFile"
            //view = self.mapViewCalloutAccessoryAction("Download", annotation: annotation, identifier: identifier)
            return nil
        } else if (t.containsString("Download")) {
            let identifier = "downloadFile"
            view = self.mapViewCalloutAccessoryAction("Download", annotation: annotation, identifier: identifier)
        } else {
            let identifier = "deleteFile"
            view = self.mapViewCalloutAccessoryAction("Delete", annotation: annotation, identifier: identifier)
        }
        return view
    }
    
    func mapViewCalloutAccessoryAction(calloutAction: String, annotation: MKAnnotation, identifier: String)-> MKAnnotationView? {
        var view : MKAnnotationView! = nil
        view = self.mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
        if view == nil {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: -5, y: 5)
            //view!.animatesDrop = true
            
            let image = UIImage(named:calloutAction)
            let button = UIButton(type: UIButtonType.DetailDisclosure)
            button.setImage(image, forState: UIControlState.Normal)
            view!.leftCalloutAccessoryView = button as UIView
            
            // if the annotation title contains Download, allow drag option
            if (calloutAction.containsString("Download")) {
                view.draggable = true
            } else {
                view.draggable = false
            }
        }
        return view
    }
    
    func initiateDownload(annotationView view: MKAnnotationView, tableCellItem2Add: String, hgtFileName: String) {
        // check if the data already downloaded and exists in the table..
        // don't download if its there already
        if (pickerData.contains(tableCellItem2Add)) {
            let alertController = UIAlertController(title: hgtFileName, message: "File Already Exists.", preferredStyle: .Alert)
            let ok = UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
            })
            alertController.addAction(ok)
            presentViewController(alertController, animated: true, completion: nil)
        } else{
            let srtmDataRegion = self.getHgtRegion(hgtFileName)
            
            if (srtmDataRegion.isEmpty == false) {
                ActivityIndicator.show("Downloading")
                let hgtFilePath: String = Srtm.DOWNLOAD_SERVER + srtmDataRegion + "/" + hgtFileName + ".zip"
                let url = NSURL(string: hgtFilePath)
                let hgtDownloader:HGTDownloader = HGTDownloader(onDownload: { path in
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        () -> Void in
                        ActivityIndicator.hide(success: true, animated: true)
                        self.mapView.removeAnnotations(self.mapView.annotations)
                        self.refresh()
                    }
                    
                    }, onError: { filename in
                        ActivityIndicator.hide(success: false, animated: true, errorMsg: "Could not retrive file")
                })
                hgtDownloader.downloadFile(url!)
            }
        }
    }
    
    func getHgtRegion(hgtFileName: String) -> String {
        return HGTRegions.filePrefixToRegion[hgtFileName]!
    }
    
    func didFailToReceieveResponse(error: String) {
        ActivityIndicator.hide(success: false, animated: true, errorMsg: error)
        print("\(error)")
    }
    
//    func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
//        if gestureRecognizer.state == UIGestureRecognizerState.Began {
//            gestureRecognizerStateBegan(gestureRecognizer)
//        }
//    }
    
//    func gestureRecognizerStateBegan(gestureRecognizer: UILongPressGestureRecognizer) {
//        let touchLocation:CGPoint = gestureRecognizer.locationInView(mapView)
//        self.mapView.removeAnnotations(mapView.annotations)
//        let locationCoordinate = mapView.convertPoint(touchLocation,toCoordinateFromView: mapView)
//        let tempHgt = Hgt(coordinate: locationCoordinate)
//        
//        if tempHgt.hasHgtFileInDocuments() {
//            let title = "Delete \(tempHgt.filenameWithExtension) File?"
//            pinAnnotation(title, coordinate:locationCoordinate)
//        } else if (!getHgtRegion(tempHgt.filenameWithExtension).isEmpty) {
//            let title = "Download Tile?"
//            pinAnnotation(title, subtitle: tempHgt.filenameWithExtension, coordinate:locationCoordinate)
//        } else {
//            var style = ToastStyle()
//            style.messageColor = UIColor.redColor()
//            style.backgroundColor = UIColor.whiteColor()
//            style.messageFont = UIFont(name: "HelveticaNeue", size: 16)
//            self.view.makeToast("Data unavailable for this location", duration: 1.5, position: .Center, style: style)
//        }
//    }
    
    
    func initiateDelete(hgtFileName: String?) {
        let alertController = UIAlertController(title: "Delete selected data File?", message: "", preferredStyle: .Alert)
        let ok = UIAlertAction(title: "OK", style: .Default, handler: {
            (action) -> Void in
            //self.deleteFile(hgtFileName)
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


