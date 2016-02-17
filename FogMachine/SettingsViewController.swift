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
    
    
    @IBOutlet weak var copyDemoFiles: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var mapLogSwitch: UISwitch!

    
    // MARK: IBActions
    
    
    @IBAction func hideKeyboard(sender: AnyObject) {
        scrollView.endEditing(true)
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



