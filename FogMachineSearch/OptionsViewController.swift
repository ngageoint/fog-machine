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
    let optionsObj = Options.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
        if (optionsObj.viewshedAlgorithmName == 0 || optionsObj.viewshedAlgorithmName == 1) {
            segmentedControl.selectedSegmentIndex = optionsObj.viewshedAlgorithmName
        } else {
            segmentedControl.selectedSegmentIndex = 0
        }
        // Do any additional setup after loading the view, typically from a nib.
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func segmentControlOptionAction(sender: AnyObject) {
        self.optionsObj.viewshedAlgorithmName = segmentedControl.selectedSegmentIndex
        //if(segmentedControl.selectedSegmentIndex == 0) {
        //    self.optionsObj.viewshedAlgorithmName = 0
       // }
       // else if(segmentedControl.selectedSegmentIndex == 1) {
       //     self.optionsObj.viewshedAlgorithmName = 2
       // }
    }

    
}