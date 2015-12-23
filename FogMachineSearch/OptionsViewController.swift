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

        
        hgtDataPickerView = UIPickerView()
        hgtDataPickerView.delegate = self
        hgtDataText.inputView = hgtDataPickerView
        
        
        radiusSlider.minimumValue = 100
        radiusSlider.maximumValue = 1200
        radiusSlider.value = 100
        
        radiusValueLText.delegate = self
        radiusValueLText.keyboardType = UIKeyboardType.DecimalPad

        radiusValueLText.text = "100"
        
        getHgtFileInfo()
        hgtDataPickerView.hidden = true;

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
    
    @IBAction func segmentControlOptionAction(sender: AnyObject) {
        self.optionsObj.viewshedAlgorithm = ViewshedAlgorithm(rawValue: viewshedTypeSegmented.selectedSegmentIndex)!
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
        hgtDataText.text = pickerData[row]
        hgtDataPickerView.hidden = true;
        self.view.endEditing(true)
    }

    
    @IBAction func radiusTextEditingDidEnd(sender: UITextField, forEvent event: UIEvent) {
        var radiusValue: Int!
        if let enteredRadiusValue: Int! = Int (radiusValueLText.text!) {
            radiusValue = enteredRadiusValue
            return
        }
        if (radiusValue >= 100 && radiusValue < 1200) {
            radiusSlider.value = Float(radiusValue)
        }
    }
    
    @IBAction func radiusSliderValueChanged(sender: UISlider) {
        let step: Float = 5
        
        let roundedValue = Int(round(radiusSlider.value / step) * step)
        radiusValueLText.text = String (roundedValue)
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
            // for the current locale. Limit its contents to a maximum of 5 characters.
        case radiusValueLText:
            let decimalSeparator = NSLocale.currentLocale().objectForKey(NSLocaleDecimalSeparator) as! String
            

            if( prospectiveText.isNumeric() &&
                prospectiveText.doesNotContainCharactersIn("-e" + decimalSeparator) &&
                prospectiveText.characters.count <= 4 && (Int(prospectiveText) < 1200)) {
                if (Int(prospectiveText) >= 100 && Int(prospectiveText) < 1200) {
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
                        
                        pickerData.append("Lat: \(self.coordinate.latitude), Lng: \(self.coordinate.longitude)")
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



