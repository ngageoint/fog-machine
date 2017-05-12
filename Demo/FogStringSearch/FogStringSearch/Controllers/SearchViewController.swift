import UIKit
import FogMachine
import SwiftEventBus

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class SearchViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var textToFind: UITextField!
    @IBOutlet weak var logBox: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textToFind.delegate = self
        
        // log any info from Fog Machine to our textbox
        SwiftEventBus.onMainThread(self, name: SearchEventBusEvents.onLog) { result in
            let format: String = result.object as! String
            self.SearchLog(format)
        }
    }
    
    // called when 'return' key pressed in textToFind.
    func textFieldShouldReturn(_ textField: UITextField ) -> Bool {
        textField.resignFirstResponder()
        return true;
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onSearch(_ sender: AnyObject) {
        if(textToFind.text != nil && textToFind.text?.characters.count > 0) {
            initiateFogSearch(textToFind.text!)
        }
    }
    
    func initiateFogSearch(_ searchTerm: String) {
        (FogMachine.fogMachineInstance.getTool() as! SearchTool).searchTerm = searchTerm
        FogMachine.fogMachineInstance.execute()
    }
    
    func SearchLog(_ format: String, writeToDebugLog:Bool = false, clearLog: Bool = false) {
        if(writeToDebugLog) {
            NSLog(format)
        }
        DispatchQueue.main.async {
            if(clearLog) {
                self.logBox.text = ""
            }
            let dateFormater = DateFormatter()
            dateFormater.dateFormat = DateFormatter.dateFormat(fromTemplate: "HH:mm:ss.SSS", options: 0, locale:  Locale.current)
            let currentTimestamp:String = dateFormater.string(from: Date());
            DispatchQueue.main.async {
                self.logBox.text.append(currentTimestamp + " " + format + "\n")
                self.logBox.scrollRangeToVisible(NSMakeRange(self.logBox.text.characters.count - 1, 1));
            }
        }
    }

}
