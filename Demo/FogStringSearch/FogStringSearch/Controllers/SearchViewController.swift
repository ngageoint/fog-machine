import UIKit
import FogMachine
import SwiftEventBus

class SearchViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var textToFind: UITextField!
    @IBOutlet weak var logBox: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textToFind.delegate = self
        
        // log any info from Fog Machine to our textbox
        SwiftEventBus.onMainThread(self, name: SearchEventBusEvents.onLog) { result in
            let format:String = result.object as! String
            self.SearchLog(format)
        }
    }
    
    // called when 'return' key pressed in textToFind.
    func textFieldShouldReturn(textField: UITextField ) -> Bool {
        textField.resignFirstResponder()
        return true;
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onSearch(sender: AnyObject) {
        if(textToFind.text != nil && textToFind.text?.characters.count > 0) {
            initiateFogSearch(textToFind.text!)
        }
    }
    
    func initiateFogSearch(searchTerm: String) {
        (FogMachine.fogMachineInstance.getTool() as! SearchTool).searchTerm = searchTerm
        FogMachine.fogMachineInstance.execute()
    }
    
    func SearchLog(format: String, writeToDebugLog:Bool = false, clearLog: Bool = false) {
        if(writeToDebugLog) {
            NSLog(format)
        }
        dispatch_async(dispatch_get_main_queue()) {
            if(clearLog) {
                self.logBox.text = ""
            }
            let dateFormater = NSDateFormatter()
            dateFormater.dateFormat = NSDateFormatter.dateFormatFromTemplate("HH:mm:ss.SSS", options: 0, locale:  NSLocale.currentLocale())
            let currentTimestamp:String = dateFormater.stringFromDate(NSDate());
            dispatch_async(dispatch_get_main_queue()) {
                self.logBox.text.appendContentsOf(currentTimestamp + " " + format + "\n")
                self.logBox.scrollRangeToVisible(NSMakeRange(self.logBox.text.characters.count - 1, 1));
            }
        }
    }

}
