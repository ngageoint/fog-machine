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
    
    
    @IBAction func hideKeyboard(_ sender: AnyObject) {
        scrollView.endEditing(true)
    }
    
    
    @IBAction func resetSettings(_ sender: AnyObject) {
        loadObserverSettings()
    }
    
    
    // MARK: Functions
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
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
            let mapViewController = segue.destination as! ViewshedViewController
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
    
    
    func saveObserverSettings(_ editedObserver: Observer) {
        model.delete(originalObserver!)
        _ = model.add(editedObserver)
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
    
    func getDoubleValue(_ key: String, value: String?, warningMessage: Warning) -> Double? {
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
    
    func alertUser(_ message: String) {
        let alertController = UIAlertController(title: "Observer Settings Error", message: message, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.cancel) { (action) in

        }
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true) {
            
        }
    }

    
}
