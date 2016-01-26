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

class ObserverSettingsViewController: UIViewController {
    
    let defaults = NSUserDefaults.standardUserDefaults()
    
    @IBOutlet weak var algorithm: UISegmentedControl!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBAction func hideKeyboard(sender: AnyObject) {
        scrollView.endEditing(true)
    }
    
    @IBAction func resetSettings(sender: AnyObject) {
        loadObserverDefaults()
    }
    
    @IBAction func applySettings(sender: AnyObject) {
        saveUserSettings()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadUserSettings()
        
    }
    
    
    func saveUserSettings() {
        defaults.setInteger(algorithm.selectedSegmentIndex, forKey: FogViewshed.ALGORITHM)
    }
    
    
    func loadUserSettings() {
        loadObserverDefaults()
        
        //Pull any saved settings from User Details
        if let userDefaultAlgorithm: Int = defaults.integerForKey(FogViewshed.ALGORITHM) {
            algorithm.selectedSegmentIndex = userDefaultAlgorithm
        }
        
    }
    
    
    func loadObserverDefaults() {
        algorithm.selectedSegmentIndex = 0
        
        //Need to hook in the following
        
        //Radius
        //Observer Name
        //Observer latitude
        //Observer longitude
        //Observer elevation
    }
    

    
}
