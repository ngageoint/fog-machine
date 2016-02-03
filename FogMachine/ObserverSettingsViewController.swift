//
//  ObserverSettingsViewController.swift
//  FogMachine
//
//  Created by Chris Wasko on 1/25/16.
//  Copyright © 2016 NGA. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class ObserverSettingsViewController: UIViewController, UITextFieldDelegate {
    
    
    // MARK: Variables
    
    
    var originalObserver : ObserverEntity?
    var model = ObserverFacade()
    
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
    
    
    @IBAction func hideKeyboard(sender: AnyObject) {
        scrollView.endEditing(true)
    }
    
    
    @IBAction func resetSettings(sender: AnyObject) {
        loadObserverSettings()
    }
    
    
    // MARK: Functions
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "applyObserverSettings" {
            let editedObserver = createObserverFromSettings()
            saveObserverSettings(editedObserver)
        } else if segue.identifier == "removePinFromSettings" {
            model.deleteObserver(originalObserver!)
        } else if segue.identifier == "runSelectedFogViewshed" {
            let editedObserver = createObserverFromSettings()
            saveObserverSettings(editedObserver)
            let mapViewController = segue.destinationViewController as! MapViewController
            mapViewController.settingsObserver = editedObserver
        }
    }
    
    
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
        
        loadObserverSettings()
    }
    
    
    func saveObserverSettings(editedObserver: Observer) {
        model.deleteObserver(originalObserver!)
        model.addObserver(editedObserver)
    }
    
    
    func createObserverFromSettings() -> Observer {
        let editedObserver = Observer()
        
        editedObserver.algorithm = ViewshedAlgorithm(rawValue: algorithm.selectedSegmentIndex)!
        editedObserver.name = name.text!

        let elevationValue = getIntegerValue(FogViewshed.ELEVATION, value: elevation.text, warningMessage: Warning.POSITIVE_INTEGER)
        let radiusValue = getIntegerValue(FogViewshed.RADIUS, value: radius.text, warningMessage: Warning.POSITIVE_INTEGER)
        let latitudeValue = getDoubleValue(FogViewshed.LATITUDE, value: latitude.text, warningMessage: Warning.DECIMAL)
        let longitudeValue = getDoubleValue(FogViewshed.LONGITUDE, value: longitude.text, warningMessage: Warning.DECIMAL)
        
        if elevationValue != nil && radiusValue != nil && latitudeValue != nil && longitudeValue != nil {
            editedObserver.elevation = elevationValue!
            editedObserver.radius = radiusValue!
            editedObserver.coordinate = CLLocationCoordinate2DMake(latitudeValue!, longitudeValue!)
        }
        
        editedObserver.updateXYLocation()
        
        return editedObserver
    }
    
    
    func getDoubleValue(key: String, value: String?, warningMessage: Warning) -> Double? {
        guard let doubleValue = Double(value!) else {
            alertUser("The \(key) requires a \(warningMessage.rawValue).")
            return nil
        }
        
        return doubleValue
    }
    
    
    func getIntegerValue(key: String, value: String?, warningMessage: Warning) -> Int? {
        guard let integerValue = Int(value!) else {
            alertUser("The \(key) requires a \(warningMessage.rawValue).")
            return nil
        }
        
        guard integerValue > 0 else {
            alertUser("The \(key) requires a \(warningMessage.rawValue).")
            return nil
        }
        
        return integerValue
    }
    
    
    func loadObserverSettings() {
        algorithm.selectedSegmentIndex = Int(originalObserver!.algorithm)
        name.text = originalObserver!.name
        elevation.text = String(originalObserver!.elevation)
        radius.text = String(originalObserver!.radius)
        latitude.text = String(originalObserver!.latitude)
        longitude.text = String(originalObserver!.longitude)
    }
    
    
    func alertUser(message: String) {
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
