//
//  OptionsViewController.swift
//  FogMachineSearch
//
//  Created by Ram Subramaniam on 11/25/15.
//  Copyright © 2015 NGA. All rights reserved.
//

import UIKit
import MapKit

class OptionsViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var radiusSlider: UISlider!
    @IBOutlet weak var viewshedTypeSegmented: UISegmentedControl!
    @IBOutlet weak var radiusValueLText: UITextField!
    @IBOutlet weak var elevationText: UITextField!
    @IBOutlet weak var observerXText: UITextField!
    @IBOutlet weak var observerYText: UITextField!

    var optionsObj = Options.sharedInstance
    

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
}



