import UIKit
import FogMachine

class SearchViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onSearch(sender: AnyObject) {
        initiateFogSearch("the")
    }
    
    func initiateFogSearch(searchTerm: String) {
        (FogMachine.fogMachineInstance.getTool() as! SearchTool).searchTerm = searchTerm
        FogMachine.fogMachineInstance.execute()
    }
}
