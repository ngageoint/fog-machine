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
        
    }
    
    @IBAction func applySettings(sender: AnyObject) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyUserSettings()
        
    }
    
    
    func applyUserSettings() {
        applyObserverDefaults()
        
        if let userDefaultAlgorithm: Int = defaults.integerForKey(FogViewshed.ALGORITHM) {
            algorithm.selectedSegmentIndex = userDefaultAlgorithm
        }
        
    }
    
    
    func applyObserverDefaults() {
        algorithm.selectedSegmentIndex = 1
    }
    

}
