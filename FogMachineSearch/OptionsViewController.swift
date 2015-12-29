//
//  OptionsViewController.swift
//  FogMachineSearch
//
//  Created by Ram Subramaniam on 11/25/15.
//  Copyright © 2015 NGA. All rights reserved.
//

import UIKit
import MapKit

class OptionsViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {
    @IBOutlet weak var radiusSlider: UISlider!
    
    @IBOutlet weak var hgtDataText: UITextField!
    @IBOutlet weak var viewshedTypeSegmented: UISegmentedControl!
    @IBOutlet weak var radiusValueLText: UITextField!
    @IBOutlet weak var elevationText: UITextField!
    @IBOutlet weak var observerXText: UITextField!
    @IBOutlet weak var observerYText: UITextField!
    var hgtDataPickerView: UIPickerView!
    
    
    var coordinate:CLLocationCoordinate2D!
    var optionsObj = Options.sharedInstance
    var pickerData: [String] = [String]()


    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        // setting the default algorithm option is none is selected before
        if (optionsObj.viewshedAlgorithm == ViewshedAlgorithm.FranklinRay || optionsObj.viewshedAlgorithm == ViewshedAlgorithm.VanKreveld) {
            viewshedTypeSegmented.selectedSegmentIndex = optionsObj.viewshedAlgorithm.rawValue
        } else {
            viewshedTypeSegmented.selectedSegmentIndex = 0
        }

        observerXText.text = "600"
        observerYText.text = "600"
        elevationText.text = "20"
        observerXText.delegate = self
        observerYText.delegate = self
        elevationText.delegate = self
        observerXText.keyboardType = UIKeyboardType.DecimalPad
        observerYText.keyboardType = UIKeyboardType.DecimalPad
        elevationText.keyboardType = UIKeyboardType.DecimalPad
        
        hgtDataPickerView = UIPickerView()
        hgtDataPickerView.delegate = self
        hgtDataText.inputView = hgtDataPickerView
        
        radiusSlider.minimumValue = 100
        radiusSlider.maximumValue = 1000
        
        radiusValueLText.delegate = self
        radiusValueLText.keyboardType = UIKeyboardType.DecimalPad
        if (self.optionsObj.radius > 0) {
            radiusValueLText.text = String (self.optionsObj.radius)
            radiusSlider.value = Float (self.optionsObj.radius)
        } else {
            radiusValueLText.text = "300"
            radiusSlider.value = 300
        }
        
        // get all the HGT File names from the resource folder
        getHgtFileInfo()
        hgtDataPickerView.hidden = true;
        
        if !self.optionsObj.selectedHGTPickerValue.isEmpty {
            hgtDataText.text = self.optionsObj.selectedHGTPickerValue
        }
        if let tmpString: String = optionsObj.selectedHGTPickerValue {
            if !tmpString.isEmpty {
                self.optionsObj.selectedHGTFile = tmpString[tmpString.startIndex.advancedBy(0)...tmpString.startIndex.advancedBy(11)]
            }
        }

    }
    // Tap outside a text field to dismiss the keyboard
    // ------------------------------------------------
    // By changing the underlying class of the view from UIView to UIControl,
    // the view can respond to events, including Touch Down, which is
    // wired to this method.
    @IBAction func userTappedBackground(sender: AnyObject) {
        view.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func segmentAlgorithmTypeChanged(sender: AnyObject) {
         self.optionsObj.viewshedAlgorithm = ViewshedAlgorithm(rawValue: viewshedTypeSegmented.selectedSegmentIndex)!
    }

    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int{
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int{
        return pickerData.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        hgtDataText.text = pickerData[row]
        hgtDataPickerView.hidden = true;
        self.view.endEditing(true)
        let pickerLine: String = pickerData[row]
        self.optionsObj.selectedHGTPickerValue = pickerLine
        self.optionsObj.selectedHGTFile = pickerLine[pickerLine.startIndex.advancedBy(0)...pickerLine.startIndex.advancedBy(11)]
        //print (self.optionsObj.selectedHGTFile)
    }

    @IBAction func observerXTextEditingDidEnd(sender: UITextField) {
        self.optionsObj.observerX = Int(observerXText.text!)!
    }

    @IBAction func observerYTextEditingDidEnd(sender: UITextField) {
        self.optionsObj.observerY = Int(observerYText.text!)!
    }
    
    @IBAction func observerElevationTextEditingDidEnd(sender: UITextField) {
        self.optionsObj.observerElevation = Int(elevationText.text!)!
    }

    @IBAction func radiusTextEditingDidEnd(sender: UITextField, forEvent event: UIEvent) {
        var radiusValue: Int!
        if let enteredRadiusValue: Int! = Int (radiusValueLText.text!) {
            radiusValue = enteredRadiusValue
        }
        if (radiusValue >= 100 && radiusValue < 1000) {
            radiusSlider.value = Float(radiusValue)
            self.optionsObj.radius = radiusValue
        }
    }
    
    @IBAction func radiusSliderValueChanged(sender: UISlider) {
        let step: Float = 5
        
        let roundedValue = Int(round(radiusSlider.value / step) * step)
        radiusValueLText.text = String (roundedValue)
        self.optionsObj.radius = roundedValue
    }
    
    // Dismiss the keyboard when the user taps the "Return" key or its equivalent
    // while editing a text field.
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true;
    }
    
    // MARK: UITextFieldDelegate events and related methods
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        // We ignore any change that doesn't add characters to the text field.
        // These changes are things like character deletions and cuts, as well
        // as moving the insertion point.

        // We still return true to allow the change to take place.
        if string.characters.count == 0 {
            return true
        }
        
        // Check to see if the text field's contents still fit the constraints
        // with the new content added to it.
        // If the contents still fit the constraints, allow the change
        // by returning true; otherwise disallow the change by returning false.
        let currentText = textField.text ?? ""
        let prospectiveText = (currentText as NSString).stringByReplacingCharactersInRange(range, withString: string)
        
        switch textField {
            
            // In this field, allow only values that evalulate to proper numeric values and
            // do not contain the "-" and "e" characters, nor the decimal separator character
            // for the current locale. Limit its contents to a maximum of 4 characters.
        case elevationText:
            let decimalSeparator = NSLocale.currentLocale().objectForKey(NSLocaleDecimalSeparator) as! String
            if( prospectiveText.isNumeric() &&
                prospectiveText.doesNotContainCharactersIn("-e" + decimalSeparator) &&
                prospectiveText.characters.count <= 4 && (Int(prospectiveText) <= 9999)) {
                    return true
            } else {
                return false
            }
        case observerYText:
            let decimalSeparator = NSLocale.currentLocale().objectForKey(NSLocaleDecimalSeparator) as! String
            if( prospectiveText.isNumeric() &&
                prospectiveText.doesNotContainCharactersIn("-e" + decimalSeparator) &&
                prospectiveText.characters.count <= 4 && (Int(prospectiveText) <= 1100)) {
                    return true
            } else {
                return false
            }
        case observerXText:
            let decimalSeparator = NSLocale.currentLocale().objectForKey(NSLocaleDecimalSeparator) as! String
            if( prospectiveText.isNumeric() &&
                prospectiveText.doesNotContainCharactersIn("-e" + decimalSeparator) &&
                prospectiveText.characters.count <= 4 && (Int(prospectiveText) <= 1100)) {
                    return true
            } else {
                return false
            }
        case radiusValueLText:
            let decimalSeparator = NSLocale.currentLocale().objectForKey(NSLocaleDecimalSeparator) as! String
            

            if( prospectiveText.isNumeric() &&
                prospectiveText.doesNotContainCharactersIn("-e" + decimalSeparator) &&
                prospectiveText.characters.count <= 4 && (Int(prospectiveText) <= 600)) {
                if (Int(prospectiveText) >= 100 && Int(prospectiveText) <= 600) {
                    radiusSlider.value = Float(prospectiveText)!
                }
                return true
            } else {
                return false
            }
            // Do not put constraints on any other text field in this view
            // that uses this class as its delegate.
        default:
            return true
        }
    }
    
    
    @IBAction func hgDataTextEditingDidBegin(sender: AnyObject) {
         hgtDataPickerView.hidden = false
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
    
    func getCenterLocation() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(coordinate.latitude + Srtm3.CENTER_OFFSET,
            coordinate.longitude + Srtm3.CENTER_OFFSET)
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
                        self.coordinate = parseCoordinate(hgFileName!)
                        //let strFileName: String = String(hgFileName!)
                        
                        let countstr: Int = String(hgFileName!).characters.count
                        
                        
                        let strName = String(hgFileName!).substringWithRange(Range<String.Index>(start: String(hgFileName!).startIndex, end: String(hgFileName!).startIndex.advancedBy(countstr)))
                        
                        pickerData.append("\(hgFileWithExt) (Lat:\(self.coordinate.latitude) Lng:\(self.coordinate.longitude))")
                        
                        self.optionsObj.selectedHGTFile = hgFileWithExt
                        hgtDataText.text = pickerData[0]
                    }
                    break
                }
            }
        } catch {
            // failed to read directory – bad permissions, perhaps?
        }
        //print("Done with all the HGT Files...\n")
    }


}



