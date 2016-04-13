import UIKit
import PeerKit
import Fog
import SwiftEventBus

class FirstViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var connectionTableView: UITableView!
    @IBOutlet weak var statusLabel: UILabel!
    var checked: [Bool]!
    let CellIdentifier = "TableCellView"
    let tempPeerCount: Int = 100
    
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(FirstViewController.findPeers(_:)), forControlEvents: UIControlEvents.ValueChanged)
        
        return refreshControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        SwiftEventBus.onMainThread(self, name: "onPeerConnect") { result in
            self.updateWorkers()
        }
        
        SwiftEventBus.onMainThread(self, name: "onPeerConnect") { result in
            self.updateWorkers()
        }
    }

    
    func findPeers(refreshControl: UIRefreshControl) {
        refreshControl.endRefreshing()
    }

    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ConnectionManager.fogMachineInstance.getAllNodes().count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:UITableViewCell = self.connectionTableView.dequeueReusableCellWithIdentifier("cell")! as UITableViewCell
        if indexPath.row < ConnectionManager.fogMachineInstance.getAllNodes().count {
            let node:Node = ConnectionManager.fogMachineInstance.getAllNodes()[indexPath.row]
            if (ConnectionManager.fogMachineInstance.getSelfNode() == node) {
                cell.textLabel?.font = UIFont(name: ".SFUIText-Bold", size: 16.0)
            } else {
                cell.textLabel?.font = UIFont(name: ".SFUIText-Regular", size: 16.0)
            }
            
            cell.textLabel?.text = node.name;
            cell.detailTextLabel?.text = node.uniqueId
        }
        
        return cell
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    
    }
    
    
    func setupTableView() {
        connectionTableView.delegate = self
        connectionTableView.dataSource = self
        connectionTableView.addSubview(self.refreshControl)
    }

    
    func updateWorkers() {
        if (ConnectionManager.fogMachineInstance.getPeerNodes().count > 0) {
            self.statusLabel.text = "Connections"
        } else {
            self.statusLabel.text = "Searching for peers..."
        }
        
        connectionTableView.reloadData()
        //print("Peers - updateWorkers : \(self.optionsObj.selectedPeers)")
    }
}

