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
    var checked: [Bool]!
    let CellIdentifier = "TableCellView"
    let tempPeerCount: Int = 100
    var optionsObj = Options.sharedInstance

    
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
        PeerKit.transceive(Fog.SERVICE_TYPE)
        refreshControl.endRefreshing()
        //print("Selected Peers (findPeers): \(self.optionsObj.selectedPeers)")
    }

    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //print("tableView->ConnectionManager.allWorkers.count : \(ConnectionManager.allWorkers.count)")
        return ConnectionManager.allWorkers.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell =  self.connectionTableView.dequeueReusableCellWithIdentifier(CellIdentifier, forIndexPath: indexPath) as UITableViewCell
        
        // set cell label
        let strPeerName: String = ConnectionManager.allWorkers[indexPath.row].displayName
        cell.textLabel?.text = strPeerName
        if (!self.optionsObj.selectedPeers.contains(strPeerName)) {
            if (checked[indexPath.row]) {
                self.optionsObj.selectedPeers.append(strPeerName)
            }
        }

        if checked[indexPath.row] {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }
        if (self.optionsObj.selectedPeers.count > ConnectionManager.allWorkers.count) {
            self.optionsObj.selectedPeers.removeAll()
            for (var i=0; i < ConnectionManager.allWorkers.count; i++) {
                let strPeerName: String = ConnectionManager.allWorkers[i].displayName
                self.optionsObj.selectedPeers.append(strPeerName)
            }
        }
        //print("Selected Peers : \(self.optionsObj.selectedPeers)")
        return cell
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (indexPath.row == 0) {
        } else {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            checked[indexPath.row] = !checked[indexPath.row]
            let strPeerName: String = ConnectionManager.allWorkers[indexPath.row].displayName
            if (checked[indexPath.row]) {
                if (!self.optionsObj.selectedPeers.contains(strPeerName)) {
                    self.optionsObj.selectedPeers.append(strPeerName)
                }
            } else {
                let index: Int! = self.optionsObj.selectedPeers.indexOf(strPeerName)
                self.optionsObj.selectedPeers.removeAtIndex(index)
            }
        }

        //print("Selected Peers->tableView : \(self.optionsObj.selectedPeers)")
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }
    
    func setupTableView() {
        checked = [Bool](count: tempPeerCount, repeatedValue: true)
        connectionTableView.dataSource = self
        connectionTableView.delegate = self
        connectionTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: CellIdentifier)
        connectionTableView.addSubview(self.refreshControl)
    }
    
    func updateWorkers() {
        if (ConnectionManager.otherWorkers.count > 0) {
            self.statusLabel.text = "Connected peers:"
        } else {
            self.statusLabel.text = "Searching for Fog Machines..."
        }
        
        connectionTableView.reloadData()
        //print("Peers - updateWorkers : \(self.optionsObj.selectedPeers)")
    }
}

