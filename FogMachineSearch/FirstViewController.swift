//
//  FirstViewController.swift
//  FogMachineSearch
//
//  Created by Tyler Burgett on 8/10/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

import UIKit
import PeerKit

class FirstViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var connectionTableView: UITableView!
    @IBOutlet weak var statusLabel: UILabel!

    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "findPeers:", forControlEvents: UIControlEvents.ValueChanged)
        
        return refreshControl
    }()
    
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
    }

    
    func findPeers(refreshControl: UIRefreshControl) {
        ConnectionManager.start()
        refreshControl.endRefreshing()
    }

    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ConnectionManager.allWorkers.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:ConnectionCell = self.connectionTableView.dequeueReusableCellWithIdentifier("cell") as! ConnectionCell
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
        connectionTableView.addSubview(self.refreshControl)
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

