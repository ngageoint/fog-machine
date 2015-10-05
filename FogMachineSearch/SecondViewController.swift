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
    
    var searchResultTotal = 0
    var responsesRecieved = Dictionary<String, Bool>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.statusField.text = "Connected to \(ConnectionManager.otherWorkers.count) peers"
        
        ConnectionManager.onEvent(Event.StartSearch){ peerID, object in
            self.logArea.text = ("Recieved request to initiate a search from \(peerID.displayName)")
            
            let dict = object as! [String: NSData]
            let workArray = WorkArray(mpcSerialized: dict["workArray"]!)
            var totalCount = 0
            var searchTerm = ""
            var returnTo = ""
            
            for work:Work in workArray.array {
                returnTo = work.searchInitiator
                if work.assignedTo == Worker.getMe().name {
                    searchTerm = work.searchTerm
                    self.logArea.text = ("Beginning search for \"\(work.searchTerm)\" from indecies \(work.lowerBound) to \(work.upperBound)\n\n\(self.logArea.text)")
                    totalCount += self.performSearch(work)
                }
            }
            
            self.logArea.text = ("Found '\(searchTerm)' \(totalCount) times. Sending results back.\n\n\(self.logArea.text)")
            let result = Work(lowerBound: "", upperBound: "", searchTerm: searchTerm, assignedTo: Worker.getMe().name, searchResults: "\(totalCount)", searchInitiator: returnTo)
            ConnectionManager.sendEvent(Event.SendResult, object: ["searchResult": result])
        }
        
        
        ConnectionManager.onEvent(Event.SendResult) { peerID, object in
            var dict = object as! [NSString: NSData]
            let result = Work(mpcSerialized: dict["searchResult"]!)
            
            if (result.searchInitiator == Worker.getMe().name) {
                self.responsesRecieved[peerID.displayName] = true
                self.searchResultTotal += Int(result.searchResults) ?? 0
                self.logArea.text = ("Result recieved from \(peerID.displayName): \(result.searchResults) found. \n\n\(self.logArea.text)")
                
                // check to see if all responses have been recieved
                var allRecieved = true
                for (_, didRespond) in self.responsesRecieved {
                    if didRespond == false {
                        allRecieved = false
                        break
                    }
                }
                
                if allRecieved {
                    self.logArea.text = ("Search complete \(self.searchResultTotal)\n\n\(self.logArea.text)")
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func performSearch(work:Work) -> Int {
        var numberFound = 0
        let lowerBound:Int = Int(work.lowerBound)!
        let upperBound:Int = Int(work.upperBound)!
        
        self.logArea.text = "Initiating search on \(work.assignedTo) from \(lowerBound) to \(upperBound)\n\n\(self.logArea.text)"
        
        for index in lowerBound...upperBound {
            let countedSet = NSCountedSet()
            let convertedText:NSString = "\(MonteCristo.paragraphs[index])" as NSString
            convertedText.enumerateSubstringsInRange(NSMakeRange(0, convertedText.length), options: NSStringEnumerationOptions.ByWords) { (substring, substringRange, enclosingRange, stop) -> Void in
                countedSet.addObject(substring!)
            }
            
            numberFound += countedSet.countForObject(work.searchTerm)

        }
        
        return numberFound
    }
    
    
    @IBAction func searchButtonTapped(sender: AnyObject) {
        let searchTerm = searchField.text ?? "Enter a Search Term"
        self.searchResultTotal = 0
        self.searchField.resignFirstResponder()
        self.logArea.text = "Beginning search for \"\(searchTerm)\""
        
        let numberOfPeers = ConnectionManager.allWorkers.count
        let totalWorkUnits = MonteCristo.paragraphs.count
        let workDivision = totalWorkUnits / numberOfPeers
        
        var startBound:Int = 0
        var tempArray = [Work]()
        
        
        for peer in ConnectionManager.allWorkers {
            self.responsesRecieved[peer.name] = false
            
            let lower = startBound == 0 ? 1 : startBound
            let upper = startBound + workDivision >= totalWorkUnits ? totalWorkUnits : startBound + workDivision
            
            let work = Work(lowerBound: "\(lower)", upperBound: "\(upper)", searchTerm: searchTerm, assignedTo: peer.name, searchResults: "", searchInitiator: Worker.getMe().name)
            tempArray.append(work)
            startBound += workDivision + 1
            
            if peer.name == Worker.getMe().name {
                let initiatingNodeResults = self.performSearch(work)
                self.responsesRecieved[Worker.getMe().name] = true
                self.searchResultTotal += initiatingNodeResults
                self.logArea.text = "Found \(initiatingNodeResults) results locally.\n\n\(self.logArea.text)"
            }
        }
        
        let workArray = WorkArray(array: tempArray)
        
        ConnectionManager.sendEvent(Event.StartSearch, object: ["workArray": workArray])
    }
}

