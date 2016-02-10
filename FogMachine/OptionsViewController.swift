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
    
    @IBAction func copyDemoFilesAction(sender: AnyObject) {
        ActivityIndicator.show("Copying..", disableUI: false)
        let fm = NSFileManager.defaultManager()
        let sourceDataPath = NSBundle.mainBundle().resourcePath!
        let targetDir = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let targetDirPath:String = "\(targetDir[0])"
        do {

            let items = try fm.contentsOfDirectoryAtPath(sourceDataPath)
            for item: String in items {
                if (item == "HGT") {
                    let hgtFolder = sourceDataPath + "/HGT"
                    let hgtFiles = try fm.contentsOfDirectoryAtPath(hgtFolder)
                    for hgFileWithExt: String in hgtFiles {
                        if hgFileWithExt.hasSuffix(".hgt") {
                            do {
                                let fileNameWithPath = targetDirPath + "/" + hgFileWithExt
                                if !(fm.fileExistsAtPath(fileNameWithPath)) {
                                    try fm.copyItemAtPath(hgtFolder + "/" + hgFileWithExt, toPath: targetDirPath + "/" + hgFileWithExt)
                                } else {
                                    print(hgFileWithExt + " File already exists in this destination...")
                                }
                            }
                            catch let error as NSError {
                                print("Error! Something went wrong: \(error)")
                            }
                        }
                    }
                    ActivityIndicator.hide(success: true, animated: true)
                    break
                }
            }
        } catch let error as NSError  {
            print("Could get the HGT files: \(error.localizedDescription)")
        }
    }
    
    
    @IBOutlet weak var copyDemoFiles: UIButton!
    
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



