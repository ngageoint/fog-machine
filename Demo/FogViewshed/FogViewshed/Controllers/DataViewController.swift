import UIKit
import MapKit
import Toast_Swift
import EZLoadingActivity

class DataViewController: UIViewController, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate, UIGestureRecognizerDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var gpsButton: UIButton!
    
    let locationManager: CLLocationManager = CLLocationManager()
    let arrowPressedImg = UIImage(named: "ArrowPressed")! as UIImage
    let arrowImg = UIImage(named: "Arrow")! as UIImage
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.backgroundColor = UIColor.clear
        tableView.delegate = self
        tableView.dataSource = self
        
        mapView.showsUserLocation = true
        mapView.tintColor = UIColor.blue
        mapView.delegate = self
        
        let onPressGesture = UILongPressGestureRecognizer(target: self, action:#selector(DataViewController.onPress(_:)))
        onPressGesture.minimumPressDuration = 0.2
        mapView.addGestureRecognizer(onPressGesture)
        

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        let status = CLLocationManager.authorizationStatus()
        if (status == .notDetermined || status == .denied || status == .restricted)  {
            locationManager.requestAlwaysAuthorization()
        } else {
            locationManager.startUpdatingLocation()
        }
        gpsButton.setImage(arrowPressedImg, for: UIControlState())
        redraw()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func focusToCurrentLocation(_ sender: AnyObject) {
        self.locationManager.startUpdatingLocation()
        gpsButton.setImage(arrowPressedImg, for: UIControlState())
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        let view = self.mapView.subviews[0]
        //  Look through gesture recognizers to determine whether this region change is from user interaction
        if let gestureRecognizers = view.gestureRecognizers {
            for recognizer in gestureRecognizers {
                if( recognizer.state == UIGestureRecognizerState.began || recognizer.state == UIGestureRecognizerState.ended ) {
                    gpsButton.setImage(arrowImg, for: UIControlState())
                }
            }
        }
    }
    
    // MARK: - Location Delegate Methods
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if (status == .authorizedWhenInUse || status == .authorizedAlways) {
            self.locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locationManager.stopUpdatingLocation()
        // most recent is at the end
        let location: CLLocation = locations.last!
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
        self.mapView?.centerCoordinate = location.coordinate
        self.mapView.setRegion(region, animated: true)
    }

    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error: " + error.localizedDescription)
    }
   
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dataCell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "dataCell", for: indexPath)
        dataCell.textLabel!.text = HGTManager.getLocalHGTFiles()[indexPath.row].filename
        dataCell.tag = indexPath.row
        return dataCell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return HGTManager.getLocalHGTFiles().count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let currentCell = tableView.cellForRow(at: indexPath)! as UITableViewCell
        
        let hgtFile: HGTFile = HGTManager.getLocalHGTFiles()[currentCell.tag]
        pinAnnotation("Delete " + hgtFile.filename + "?", coordinate: hgtFile.getBoundingBox().getCentroid())
    }
    
    
    func drawDataRegions() {
        var dataRegionOverlays = [MKOverlay]()
        for overlay in mapView.overlays {
            if overlay is MKPolygon {
                dataRegionOverlays.append(overlay)
            }
        }
        mapView.removeOverlays(dataRegionOverlays)
        
        for hgtFile in HGTManager.getLocalHGTFiles() {
            self.mapView.add(hgtFile.getBoundingBox().asMKPolygon())
        }
    }
    
    func redraw() {
        self.mapView.removeAnnotations(mapView.annotations)
        drawDataRegions()
    }
    
    func refresh() {
        redraw()
        self.tableView?.reloadData()
    }
    
    func pinAnnotation(_ title: String, subtitle: String = "", coordinate: CLLocationCoordinate2D) {
        // remove all the annotations on the map
        self.mapView.removeAnnotations(mapView.annotations)
        
        // Now setup the region based on the lat/lon and retain the span that already exists.
        let region = MKCoordinateRegion(center: coordinate, span: self.mapView.region.span)
        //Center the view with some animation.
        self.mapView.setRegion(region, animated: true)
        
        let pointAnnotation: MKPointAnnotation = MKPointAnnotation()
        pointAnnotation.coordinate = coordinate
        pointAnnotation.title = title
        pointAnnotation.subtitle = subtitle
        self.mapView.addAnnotation(pointAnnotation)
    }

    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let defaultOverlay = MKPolygonRenderer()
        if overlay is MKPolygon {
            let polygonView = MKPolygonRenderer(overlay: overlay)
            polygonView.lineWidth = 0.5
            polygonView.fillColor = UIColor.yellow.withAlphaComponent(0.4)
            polygonView.strokeColor = UIColor.red.withAlphaComponent(0.6)

            return polygonView
        }
        return defaultOverlay
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        // if the annotation is dragged to a different location, handle it
        if newState == MKAnnotationViewDragState.ending {
            //let droppedAt = view.annotation?.coordinate
            let annotation = view.annotation!
            let title: String = ((view.annotation?.title)!)!
            self.pinAnnotation(title, coordinate: annotation.coordinate)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var view: MKAnnotationView! = nil
        let title: String = String(describing: annotation.title)
        if (annotation is MKUserLocation) {
            //if annotation is not an MKPointAnnotation (eg. MKUserLocation),
            //return nil so map draws default view for it (eg. blue dot)...
            //let identifier = "downloadFile"
            //view = self.mapViewCalloutAccessoryAction("Download", annotation: annotation, identifier: identifier)
            return nil
        } else if (title.contains("Download")) {
            let identifier = "downloadFile"
            view = self.mapViewCalloutAccessoryAction("Download", annotation: annotation, identifier: identifier)
        } else {
            let identifier = "deleteFile"
            view = self.mapViewCalloutAccessoryAction("Delete", annotation: annotation, identifier: identifier)
        }
        return view
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let annotation = view.annotation!
        let filename: String = HGTFile.coordinateToFilename(annotation.coordinate, resolution: Srtm.SRTM3_RESOLUTION)
        
        if view.reuseIdentifier == "downloadFile" {
            self.initiateDownload(filename)
        } else if view.reuseIdentifier == "deleteFile" {
            if let hgtFile = HGTManager.getLocalHGTFileByName(filename) {
                self.initiateDelete(hgtFile)
            }
        }
    }
    
    func mapViewCalloutAccessoryAction(_ calloutAction: String, annotation: MKAnnotation, identifier: String)-> MKAnnotationView? {
        var view: MKAnnotationView! = nil
        view = self.mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        if view == nil {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: -5, y: 5)
            
            let image = UIImage(named:calloutAction)
            let button = UIButton(type: UIButtonType.detailDisclosure)
            button.setImage(image, for: UIControlState())
            view!.leftCalloutAccessoryView = button as UIView
        }
        return view
    }
    
    func initiateDelete(_ hgtfile: HGTFile) {
        let alertController = UIAlertController(title: "Delete " + hgtfile.filename + "?", message: "", preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: {
            (action) -> Void in
            HGTManager.deleteFile(hgtfile)
            self.refresh()
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) {
            (action) -> Void in
        }
        alertController.addAction(ok)
        alertController.addAction(cancel)
        present(alertController, animated: true, completion: nil)
    }
    
    func initiateDownload(_ filename: String) {
        _ = EZLoadingActivity.show("Downloading " + filename, disableUI: false)
        let hgtDownloader: HGTDownloader = HGTDownloader(onDownload: { path in
            
            DispatchQueue.main.async {
                () -> Void in
                _ = EZLoadingActivity.hide(true, animated: false)
                self.refresh()
            }
            
            }, onError: { filename in
              _ = EZLoadingActivity.hide(false, animated: false)
        })
        hgtDownloader.downloadFile(filename)
    }
    
    func didFailToReceieveResponse(_ error: String) {
       _ = EZLoadingActivity.hide(false, animated: false)
        print("\(error)")
    }
    
    func onPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == UIGestureRecognizerState.began {

            let filename: String = HGTFile.coordinateToFilename(mapView.convert(gestureRecognizer.location(in: mapView), toCoordinateFrom: mapView), resolution: Srtm.SRTM3_RESOLUTION)
            if let hgtFile = HGTManager.getLocalHGTFileByName(filename) {
                pinAnnotation("Delete " + hgtFile.filename + "?", coordinate:hgtFile.getBoundingBox().getCentroid())
            } else {
                let srtmDataRegion: String = HGTRegions().getRegion(filename)
                if (srtmDataRegion.isEmpty == false) {
                    pinAnnotation("Download elevation data?", subtitle: filename, coordinate:mapView.convert(gestureRecognizer.location(in: mapView), toCoordinateFrom: mapView))
                } else {
                    self.view.makeToast("No data available here.", duration: 1.5, position: ToastPosition.center)
                }
            }
        }
    }
}


