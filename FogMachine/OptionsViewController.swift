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
    
  
    let defaults = NSUserDefaults.standardUserDefaults()
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBAction func hideKeyboard(sender: AnyObject) {
        scrollView.endEditing(true)
    }
    
    @IBAction func resetOptions(sender: AnyObject) {
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyUserSettings()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func applyUserSettings() {
        //Created as a default
        //Might not have anything to apply here
        
        applyDefaults()
        
    }
    
    
    func applyDefaults() {
        //Created as a default
        //Might not have anything to apply here
        
    }
    
    
    // MARK: Functions
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "applyOptions" {
            // apply Options
        }
    }

    
}



