//
//  SecondViewController.swift
//  FogMachineSearch
//
//  Created by Tyler Burgett on 8/10/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

import UIKit

class SecondViewController: UIViewController {

    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var statusField: UILabel!
    @IBOutlet weak var logArea: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.statusField.text = "Connected to \(ConnectionManager.otherWorkers.count) peers"
        
        ConnectionManager.onEvent(Event.StartSearch){ peerID, object in
            self.logArea.text = ("Recieved request to initiate a search from \(peerID.displayName)\n\(self.logArea.text)")
            
            let dict = object as! [String: NSData]
            let workArray = WorkArray(mpcSerialized: dict["workArray"]!)
            var totalCount = 0
            var searchTerm = ""
            
            for work:Work in workArray.array {
                if work.assignedTo == Worker.getMe().displayName{
                    
                    self.logArea.text = ("Beginning search for \(work.searchTerm) from indecies \(work.lowerBound) to \(work.upperBound)\n\n\(self.logArea.text)")
                    searchTerm = work.searchTerm
                    
                    var countedSet = NSCountedSet()
                    
                    for (chapterKey, chapterText) in MonteCristo.paragraphs {
                        if (chapterKey >= work.lowerBound.toInt() && chapterKey <= work.upperBound.toInt()) {
                            var convertedText:NSString = chapterText as NSString
                            convertedText.enumerateSubstringsInRange(NSMakeRange(0, convertedText.length), options: NSStringEnumerationOptions.ByWords) { (substring, substringRange, enclosingRange, stop) -> Void in
                                countedSet.addObject(substring)
                            }
                        }
                    }
                    
                    totalCount += countedSet.countForObject(work.searchTerm)
                    break
                }
            }
            
            self.logArea.text = ("Found \(searchTerm) \(totalCount) times. Sending results back.\n\n\(self.logArea.text)")
            var result = Work(lowerBound: "", upperBound: "", searchTerm: searchTerm, assignedTo: Worker.getMe().displayName, searchResults: "\(totalCount)")
            ConnectionManager.sendEvent(Event.SendResult, object: ["searchResult": result])
        }
        
        
        ConnectionManager.onEvent(Event.SendResult) { peerID, object in
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func performSearch(work:Work, searchTerm:String) -> Int {
        var totalCount = 0
        var countedSet = NSCountedSet()
        
        var convertedText:NSString = "\(MonteCristo.paragraphs[work.lowerBound.toInt()!])" as NSString
        convertedText.enumerateSubstringsInRange(NSMakeRange(0, convertedText.length), options: NSStringEnumerationOptions.ByWords) { (substring, substringRange, enclosingRange, stop) -> Void in
            countedSet.addObject(substring)
        }
        
        return totalCount
    }
    
    
    @IBAction func searchButtonTapped(sender: AnyObject) {
        var searchTerm = searchField.text
        self.searchField.resignFirstResponder()
        self.logArea.text = "Beginning search for \(searchTerm)..."
        
        var numberOfPeers = ConnectionManager.allWorkers.count
        var totalWorkUnits = MonteCristo.paragraphs.keys.array.count
        var workDivision = totalWorkUnits / numberOfPeers
        
        var separationOfWork: Dictionary<NSString, Work> = [:]
        
        var startBound:Int = 0
        var tempArray = [Work]()
        
        
        for peer in ConnectionManager.allWorkers {
            var lower = startBound == 0 ? 1 : startBound
            var upper = startBound + workDivision == totalWorkUnits ? totalWorkUnits : startBound + workDivision - 1
            
            var work = Work(lowerBound: "\(lower)", upperBound: "\(upper)", searchTerm: searchTerm, assignedTo: peer.displayName, searchResults: "")
            tempArray.append(work)
            startBound += workDivision
        }
        
        var workArray = WorkArray(array: tempArray)
        
        ConnectionManager.sendEvent(Event.StartSearch, object: ["workArray": workArray])
    }
}

