//
//  OptionsViewController.swift
//  FogMachineSearch
//
//  Created by Ram Subramaniam on 11/25/15.
//  Copyright © 2015 NGA. All rights reserved.
//

import UIKit

class OptionsViewController: UIViewController {

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    var optionsObj = Options.sharedInstance

    @IBOutlet weak var radiusTextControl: UITextField!
    @IBOutlet weak var stepperControl: UIStepper!
    
    override func viewDidLoad() {
        super.viewDidLoad()
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

    
}