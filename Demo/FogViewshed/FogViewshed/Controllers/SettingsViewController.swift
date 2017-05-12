import UIKit
import MapKit

class SettingsViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: IBOutlets
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var mapLogSwitch: UISwitch!
    
    // MARK: IBActions
    
    
    @IBAction func hideKeyboard(_ sender: AnyObject) {
        scrollView.endEditing(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapLogSwitch.setOn(UserDefaults.standard.bool(forKey: "isLogShown"), animated: false)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onDisplayMapLog(_ sender: AnyObject) {
        UserDefaults.standard.setValue(mapLogSwitch.isOn, forKey: "isLogShown")
    }
}



