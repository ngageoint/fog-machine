//
//  OptionsViewController.swift
//  FogMachineSearch
//
//  Created by Ram Subramaniam on 11/25/15.
//  Copyright © 2015 NGA. All rights reserved.
//

import UIKit
import MapKit

class OptionsViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    //@IBOutlet weak var hgtDataTextView: UITextField!
     //@IBOutlet weak var hgtDataPickerView: UIPickerView!

    @IBOutlet weak var hgtDataTextField: UITextField!
    @IBOutlet weak var hgtDataPickerView: UIPickerView!
    @IBOutlet weak var radiusTextControl: UITextField!
    @IBOutlet weak var stepperControl: UIStepper!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var radiusSlider: UISlider!
    
    @IBOutlet weak var radiusValueLabel: UILabel!
    
    var coordinate:CLLocationCoordinate2D!
    var optionsObj = Options.sharedInstance
    //var pickerData: [String] =  ["Mozzarella", "Gorgonzola", "Provolone","Brie", "Maytag Blue", "Sharp Cheddar", "Monterrey Jack", "Stilton", "Gouda", "Goat Cheese",  "Asiago"]
    var pickerData: [String] = [String]()


    override func viewDidLoad() {
        super.viewDidLoad()
       
        //hgtDataTextView.enabled = false
        //hgtDataPickerView.dataSource = self
        //hgtDataPickerView.delegate = self
        
        
        
        // Do any additional setup after loading the view, typically from a nib.
        // setting the default algorithm option is none is selected before
        if (optionsObj.viewshedAlgorithm == ViewshedAlgorithm.FranklinRay || optionsObj.viewshedAlgorithm == ViewshedAlgorithm.VanKreveld) {
            segmentedControl.selectedSegmentIndex = optionsObj.viewshedAlgorithm.rawValue
        } else {
            segmentedControl.selectedSegmentIndex = 0
        }
        stepperControl.autorepeat = true
        stepperControl.maximumValue = 1200
        stepperControl.minimumValue = 100
        radiusTextControl.text = "100"
        
        let pickerView = UIPickerView()
        pickerView.delegate = self
        hgtDataTextField.inputView = pickerView
        
        radiusSlider.minimumValue = 100
        radiusSlider.maximumValue = 1200
        radiusSlider.value = 100
        radiusValueLabel.text = "100"
        getHgtFileInfo()

        
        //hgtDataTextField.text = pickerData[0]
    }
    
    func generateRadiusData () {

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func stepperValueChanged(sender: AnyObject) {
        radiusTextControl.text = String (Int(stepperControl.value))
        self.optionsObj.radius = Int(stepperControl.value)
    }
    @IBAction func segmentControlOptionAction(sender: AnyObject) {
        self.optionsObj.viewshedAlgorithm = ViewshedAlgorithm(rawValue: segmentedControl.selectedSegmentIndex)!
    }
    
    
    // File names refer to the latitude and longitude of the lower left corner of
    // the tile - e.g. N37W105 has its lower left corner at 37 degrees north
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
    
    func getCenterLocation() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(coordinate.latitude + Srtm3.CENTER_OFFSET,
            coordinate.longitude + Srtm3.CENTER_OFFSET)
    }

    func getHgtFileInfo() {
        
        let fm = NSFileManager.defaultManager()
        let path = NSBundle.mainBundle().resourcePath!
        print("path \(path)\n")
        do {
            let items = try fm.contentsOfDirectoryAtPath(path)
            for var item: String in items {
                if (item == "HGT") {
                    print("item:  \(item)\n")
                    let hgtFolder = path + "/HGT"
                    let hgtFiles = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(hgtFolder)
                    for var hgFileWithExt: String in hgtFiles {
                        let hgFileName = NSURL(fileURLWithPath: hgFileWithExt).URLByDeletingPathExtension?.lastPathComponent
                        self.coordinate = parseCoordinate(hgFileName!)
                        //let strFileName: String = String(hgFileName!)
                        
                        let countstr: Int = String(hgFileName!).characters.count
                        
                        
                        let strName = String(hgFileName!).substringWithRange(Range<String.Index>(start: String(hgFileName!).startIndex, end: String(hgFileName!).startIndex.advancedBy(countstr)))
                        
                        pickerData.append("Lat: \(self.coordinate.latitude), Lng: \(self.coordinate.longitude)")
                        print("name \(hgFileName)\t\t \(coordinate)")
                        // drop a pin....custom annotation.
                        //var customAnnotation = CustomPointAnnotation()
                        //customAnnotation.coordinate =  self.coordinate
                        //customAnnotation.pinImageName = "ViewshedMap"
                        //customAnnotation.title = String ("\(self.coordinate.latitude), \(self.coordinate.longitude)")
                        //annotationView = MKPinAnnotationView(annotation: customAnnotation, reuseIdentifier: "pin")
                        //self.hgtDataMap.addAnnotation(annotationView.annotation!)
                        ////hgtDataMap.addAnnotation(customAnnotation)
                        // drop a pin....annotation.
                        //let annotation = MKPointAnnotation()
                        //annotation.coordinate = self.coordinate
                        //annotation.title = String ("\(self.coordinate.latitude), \(self.coordinate.longitude)")
                        //hgtDataMap.addAnnotation(annotation)
                    }
                    break
                }
            }
        } catch {
            // failed to read directory – bad permissions, perhaps?
        }
        print("Done with all the HGT Files...\n")
    }

    
/*
    func getHgtFileInfo() {
        var annotationView:MKPinAnnotationView!
        
        let fm = NSFileManager.defaultManager()
        let path = NSBundle.mainBundle().resourcePath!
        print("path \(path)\n")
        do {
            let items = try fm.contentsOfDirectoryAtPath(path)
            for var item: String in items {
                if (item == "HGT") {
                    print("item:  \(item)\n")
                    let hgtFolder = path + "/HGT"
                    let hgtFiles = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(hgtFolder)
                    for var hgFileWithExt: String in hgtFiles {
                        let hgFileName = NSURL(fileURLWithPath: hgFileWithExt).URLByDeletingPathExtension?.lastPathComponent
                        self.coordinate = parseCoordinate(hgFileName!)
                        //print("name \(hgFileName)\t\t \(coordinate)")
                        // drop a pin....custom annotation.
                        //var customAnnotation = CustomPointAnnotation()
                        //customAnnotation.coordinate =  self.coordinate
                        //customAnnotation.pinImageName = "ViewshedMap"
                        //customAnnotation.title = String ("\(self.coordinate.latitude), \(self.coordinate.longitude)")
                        //annotationView = MKPinAnnotationView(annotation: customAnnotation, reuseIdentifier: "pin")
                        //self.hgtDataMap.addAnnotation(annotationView.annotation!)
                        ////hgtDataMap.addAnnotation(customAnnotation)
                        // drop a pin....annotation.
                        //let annotation = MKPointAnnotation()
                        //annotation.coordinate = self.coordinate
                        //annotation.title = String ("\(self.coordinate.latitude), \(self.coordinate.longitude)")
                        //hgtDataMap.addAnnotation(annotation)
                    }
                    break
                }
            }
        } catch {
            // failed to read directory – bad permissions, perhaps?
        }
        print("Done with all the HGT Files...\n")
    }
*/
    class CustomPointAnnotation: MKPointAnnotation {
        var pinImageName: String!
    }


    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int{
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int{
        return pickerData.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        return pickerData[row]
    }
    
    func pickerView(pickerView: UIPickerView!, didSelectRow row: Int, inComponent component: Int){
        hgtDataTextField.text = pickerData[row]
        //self.view.endEditing(true)
    }

    @IBAction func radiusSliderValueChanged(sender: AnyObject) {
        let step: Float = 5
        
        let roundedValue = Int(round(radiusSlider.value / step) * step)
        radiusValueLabel.text = "\(roundedValue)"
    }
}