import Foundation
import UIKit
import MapKit

class ObserverSettingsViewController: UIViewController, UITextFieldDelegate {
    
    
    // MARK: Variables
    
    var originalObserver: Observer?
    var model = ObserverFacade()
    
    enum Warning: String {
        case DECIMAL = "decimal"
    }
    
    // MARK: IBOutlets
    
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var algorithm: UISegmentedControl!
    @IBOutlet weak var elevation: UITextField!
    @IBOutlet weak var radius: UITextField!
    @IBOutlet weak var latitude: UITextField!
    @IBOutlet weak var longitude: UITextField!
    
    
    // MARK: IBActions
    
    
    @IBAction func hideKeyboard(sender: AnyObject) {
        scrollView.endEditing(true)
    }
    
    
    @IBAction func resetSettings(sender: AnyObject) {
        loadObserverSettings()
    }
    
    
    // MARK: Functions
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "applyObserverSettings" {
            let editedObserver = createObserverFromSettings()
            saveObserverSettings(editedObserver)
        } else if segue.identifier == "removePinFromSettings" {
            model.delete(originalObserver!)
        } else if(segue.identifier == "runSelectedFogViewshed"
            || segue.identifier == "drawElevationData"
            || segue.identifier == "draw3dElevationData") {
            let editedObserver = createObserverFromSettings()
            saveObserverSettings(editedObserver)
            let mapViewController = segue.destinationViewController as! ViewshedViewController
            mapViewController.settingsObserver = editedObserver
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        elevation.delegate = self
        radius.delegate = self
        latitude.delegate = self
        longitude.delegate = self
        
        loadObserverSettings()
    }
    
    
    func saveObserverSettings(editedObserver: Observer) {
        model.delete(originalObserver!)
        model.add(editedObserver)
    }
    
    func createObserverFromSettings() -> Observer {
        let editedObserver = Observer()

        let elevationValue = getDoubleValue("elevation", value: elevation.text, warningMessage: Warning.DECIMAL)
        let radiusValue = getDoubleValue("radius", value: radius.text, warningMessage: Warning.DECIMAL)
        let latitudeValue = getDoubleValue("latitude", value: latitude.text, warningMessage: Warning.DECIMAL)
        let longitudeValue = getDoubleValue("longitude", value: longitude.text, warningMessage: Warning.DECIMAL)
        
        if elevationValue != nil && radiusValue != nil && latitudeValue != nil && longitudeValue != nil {
            editedObserver.elevationInMeters = elevationValue!
            editedObserver.radiusInMeters = radiusValue!
            editedObserver.position = CLLocationCoordinate2DMake(latitudeValue!, longitudeValue!)
        }
        
        return editedObserver
    }
    
    func getDoubleValue(key: String, value: String?, warningMessage: Warning) -> Double? {
        guard let doubleValue = Double(value!) else {
            alertUser("The \(key) requires a \(warningMessage.rawValue).")
            return nil
        }
        
        return doubleValue
    }
    
    func loadObserverSettings() {        
        algorithm.selectedSegmentIndex = 0
        elevation.text = String(originalObserver!.elevationInMeters)
        radius.text = String(originalObserver!.radiusInMeters)
        latitude.text = String(originalObserver!.position.latitude)
        longitude.text = String(originalObserver!.position.longitude)
    }
    
    func alertUser(message: String) {
        let alertController = UIAlertController(title: "Observer Settings Error", message: message, preferredStyle: .Alert)
        
        let cancelAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel) { (action) in

        }
        alertController.addAction(cancelAction)
        self.presentViewController(alertController, animated: true) {
            
        }
    }

    
}
