//
//  FirstViewController.swift
//  FogMachineSearch
//
//  Created by Tyler Burgett on 8/10/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var connectionTableView: UITableView!
    @IBOutlet weak var statusLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        ConnectionManager.onConnect { _ in
            self.updateWorkers()
        }
        ConnectionManager.onDisconnect { _ in
            self.updateWorkers()
        }
        /*ConnectionManager.onEvent(.StartGame) { _, object in
            let dict = object as [String: NSData]
            let blackCard = Card(mpcSerialized: dict["blackCard"]!)
            let whiteCards = CardArray(mpcSerialized: dict["whiteCards"]!).array
            self.startGame(blackCard: blackCard, whiteCards: whiteCards)
        }*/
    }


    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ConnectionManager.allWorkers.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:ConnectionCell = self.connectionTableView.dequeueReusableCellWithIdentifier("cell") as! ConnectionCell
        // set cell label
        cell.label.text = ConnectionManager.allWorkers[indexPath.row].displayName
        return cell
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        NSLog("selected a cell")
    }
    
    func setupTableView() {
        connectionTableView.delegate = self
        connectionTableView.dataSource = self
    }
    
    func updateWorkers() {
        if (ConnectionManager.otherWorkers.count > 0) {
            self.statusLabel.text = "Connected peers:"
        } else {
            self.statusLabel.text = "Searching for Fog Machines..."
        }
        
        connectionTableView.reloadData()
    }
}

