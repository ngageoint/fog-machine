//
//  ObserverSettingsViewController.swift
//  FogMachine
//
//  Created by Chris Wasko on 1/25/16.
//  Copyright © 2016 NGA. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class ObserverSettingsViewController: UIViewController, UITextFieldDelegate {
    
    
    // MARK: Variables
    
    
    let defaults = NSUserDefaults.standardUserDefaults()
    
    enum Warning: String {
        case POSITIVE_INTEGER = "positive integer",
        DECIMAL = "decimal"
    }
    
    
    // MARK: IBOutlets
    
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var algorithm: UISegmentedControl!
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var elevation: UITextField!
    @IBOutlet weak var radius: UITextField!
    @IBOutlet weak var latitude: UITextField!
    @IBOutlet weak var longitude: UITextField!
    
    
    // MARK: IBActions
    
    
    @IBAction func removePinFromMap(sender: AnyObject) {
        print("removed!")
    }
    
    
    @IBAction func hideKeyboard(sender: AnyObject) {
        scrollView.endEditing(true)
    }
    
    
    @IBAction func resetSettings(sender: AnyObject) {
        loadObserverDefaults()
    }
    
    
    @IBAction func applySettings(sender: AnyObject) {
        saveUserSettings()
    }
    
    
    // MARK: Functions
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        elevation.delegate = self
        radius.delegate = self
        latitude.delegate = self
        longitude.delegate = self
        
        elevation.keyboardType = UIKeyboardType.NumbersAndPunctuation
        radius.keyboardType = UIKeyboardType.NumbersAndPunctuation
        latitude.keyboardType = UIKeyboardType.NumbersAndPunctuation
        longitude.keyboardType = UIKeyboardType.NumbersAndPunctuation
        
        loadUserSettings()
        
    }
    
    
    func saveUserSettings() {
        defaults.setInteger(algorithm.selectedSegmentIndex, forKey: FogViewshed.ALGORITHM)
        defaults.setObject(name.text, forKey: FogViewshed.NAME)
        saveIntegerUserSetting(elevation.text, key: FogViewshed.ELEVATION, warningMessage: Warning.POSITIVE_INTEGER)
        saveIntegerUserSetting(radius.text, key: FogViewshed.RADIUS, warningMessage: Warning.POSITIVE_INTEGER)
        saveDoubleUserSetting(latitude.text, key: FogViewshed.LATITUDE, warningMessage: Warning.DECIMAL)
        saveDoubleUserSetting(longitude.text, key: FogViewshed.LONGITUDE, warningMessage: Warning.DECIMAL)

    }
    
    
    func saveDoubleUserSetting(value: String?, key: String, warningMessage: Warning) {
        guard let doubleValue = Double(value!) else {
            alertUser("The \(key) requires a \(warningMessage).")
            return
        }

        defaults.setDouble(doubleValue, forKey: key)
    }
    
    
    func saveIntegerUserSetting(value: String?, key: String, warningMessage: Warning) {
        guard let integerValue = Int(value!) else {
            alertUser("The \(key) requires a \(warningMessage).")
            return
        }
        
        guard integerValue > 0 else {
            alertUser("The \(key) requires a \(warningMessage).")
            return
        }
        
        defaults.setInteger(integerValue, forKey: key)
    }
    
    
    func loadUserSettings() {
        loadObserverDefaults()
        
        //Pull any saved settings from User Details
        if let userDefaultAlgorithm: Int = defaults.integerForKey(FogViewshed.ALGORITHM) {
            algorithm.selectedSegmentIndex = userDefaultAlgorithm
        }
        if let userDefaultName: String = String(defaults.objectForKey(FogViewshed.NAME)) {
             name.text = userDefaultName
        }
        if let userDefaultElevation: String = String(defaults.integerForKey(FogViewshed.ELEVATION)) {
             elevation.text = userDefaultElevation
        }
        if let userDefaultRadius: String = String(defaults.integerForKey(FogViewshed.RADIUS)) {
             radius.text = userDefaultRadius
        }
        if let userDefaultLatitude: String = String(defaults.doubleForKey(FogViewshed.LATITUDE)) {
             latitude.text = userDefaultLatitude
        }
        if let userDefaultLongitude: String = String(defaults.doubleForKey(FogViewshed.LONGITUDE)) {
            longitude.text = userDefaultLongitude
        }
        
    }
    
    
    func loadObserverDefaults() {
        algorithm.selectedSegmentIndex = 0
        name.text = "Enter Name"
        elevation.text = "25"
        radius.text = "250"
        latitude.text = "39"
        longitude.text = "-74"
    }
    
    
    func alertUser(message: String) {
        //let message = "Fog Viewshed requires 1, 2, or 4 connected devices for the algorithms quadrant distribution."
        let alertController = UIAlertController(title: "Observer Settings Error", message: message, preferredStyle: .Alert)
        
        let cancelAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel) { (action) in
            //print(action)
        }
        alertController.addAction(cancelAction)
        self.presentViewController(alertController, animated: true) {
            // ...
        }
    }

    
}
