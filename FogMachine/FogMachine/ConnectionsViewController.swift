import UIKit
import SwiftEventBus

class ConnectionsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var connectionTableView: UITableView!
    @IBOutlet weak var statusLabel: UILabel!
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(ConnectionsViewController.findPeers(_:)), for: UIControlEvents.valueChanged)
        
        return refreshControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        SwiftEventBus.onMainThread(self, name: FogMachineEventBusEvents.onPeerConnect) { result in
            self.updateWorkers()
        }
        
        SwiftEventBus.onMainThread(self, name: FogMachineEventBusEvents.onPeerDisconnect) { result in
            self.updateWorkers()
        }
    }
    
    func findPeers(_ refreshControl: UIRefreshControl) {
        refreshControl.endRefreshing()
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return FogMachine.fogMachineInstance.getAllNodes().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = self.connectionTableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
        if indexPath.row < FogMachine.fogMachineInstance.getAllNodes().count {
            let node:FMNode = FogMachine.fogMachineInstance.getAllNodes()[indexPath.row]
            if (FogMachine.fogMachineInstance.getSelfNode() == node) {
                cell.textLabel?.font = UIFont(name: ".SFUIText-Bold", size: 16.0)
            } else {
                cell.textLabel?.font = UIFont(name: ".SFUIText-Regular", size: 16.0)
            }
            
            cell.textLabel?.text = node.name
            cell.detailTextLabel?.text = node.uniqueId
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    func setupTableView() {
        connectionTableView.delegate = self
        connectionTableView.dataSource = self
        connectionTableView.addSubview(self.refreshControl)
    }
    
    func updateWorkers() {
        if (FogMachine.fogMachineInstance.getPeerNodes().count > 0) {
            self.statusLabel.text = "Connections"
        } else {
            self.statusLabel.text = "Searching for peers..."
        }
        connectionTableView.reloadData()
    }
}

