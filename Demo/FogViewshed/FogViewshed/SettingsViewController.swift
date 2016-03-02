//
//  SettingsViewController.swift
//  FogMachineSearch
//
//  Created by Ram Subramaniam on 11/25/15.
//  Copyright © 2015 NGA. All rights reserved.
//

import UIKit
import MapKit

class SettingsViewController: UIViewController, UITextFieldDelegate {
    
    
    // MARK: Class Variables
    
    
    var isLogShown: Bool!
    let defaults = NSUserDefaults.standardUserDefaults()
    
    
    // MARK: IBOutlets
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var mapLogSwitch: UISwitch!

    
    // MARK: IBActions
    
    
    @IBAction func hideKeyboard(sender: AnyObject) {
        scrollView.endEditing(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setMapLogSwitch()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: Functions

    
    func setMapLogSwitch() {
        guard let isLogShown = self.isLogShown else {
            return
        }

        mapLogSwitch.setOn(isLogShown, animated: true)
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let viewController: MapViewController = segue.destinationViewController as! MapViewController
        viewController.isLogShown = mapLogSwitch.on
    }
    
}



