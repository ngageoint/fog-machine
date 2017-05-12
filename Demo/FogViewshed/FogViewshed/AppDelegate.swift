import UIKit
import CoreData
import FogMachine
import Toast_Swift
import EZLoadingActivity

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    /**
 
     This is the entry point into the application 
 
     */
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        // copy hgt files to documents dir
        let prefs = UserDefaults.standard
        prefs.register(defaults: ["isLogShown": false])
        
        // copy the data over to documents dir, if it's never been done.
        if !prefs.bool(forKey: "hasCopyData") {
            HGTManager.copyHGTFilesToDocumentsDir()
            prefs.setValue(true, forKey: "hasCopyData")
        }
        
        // init fog machine
        FogMachine.fogMachineInstance.setTool(ViewshedTool())
        FogMachine.fogMachineInstance.startSearchForPeers()
        
        var toastStyle = ToastStyle()
        toastStyle.messageAlignment = NSTextAlignment.center
        toastStyle.backgroundColor = UIColor.white
        toastStyle.messageColor = UIColor.red
        toastStyle.displayShadow = true
        toastStyle.shadowOffset = CGSize(width: 0, height: 0)
        toastStyle.shadowRadius = 5
        toastStyle.shadowOpacity = 0.5
        if let toastFont = UIFont(name: "HelveticaNeue-Light", size: 16) {
            toastStyle.messageFont = toastFont
        }
        ToastManager.shared.style = toastStyle
        
        EZLoadingActivity.Settings.BackgroundColor = UIColor.white
        EZLoadingActivity.Settings.ActivityColor = UIColor.black
        EZLoadingActivity.Settings.TextColor = UIColor.black
        EZLoadingActivity.Settings.ActivityHeight = EZLoadingActivity.Settings.ActivityWidth / 5
        
        return true
    }
    
    // Handle HGT file import from other sources
    func application(_ application: UIApplication, open hgtUrl: URL, sourceApplication: String?, annotation: Any) -> Bool {
        if hgtUrl.scheme == "file" {
            let fileManager = FileManager.default
            let documentsFolderPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
            let inboxFolderPath = (documentsFolderPath[0] as NSString).appendingPathComponent("Inbox")
            // imported HGT file name
            let hgtFileName = URL(fileURLWithPath: hgtUrl.absoluteString).lastPathComponent

            // files imported twice into the Fogmachine app named as ex: N38W075-1.hgt ...
            // so if the file name with anything like "-x" will be stripped
            let range = hgtFileName.characters.index(hgtFileName.startIndex, offsetBy: 0)..<hgtFileName.characters.index(hgtFileName.startIndex, offsetBy: 7)
            
            let hgtFileWithoutDash = hgtFileName.substring(with: range) + ".hgt"
            if (!fileManager.fileExists(atPath: documentsFolderPath[0] + "/" + hgtFileWithoutDash)) {
                do {
                    // copy the HGT file to Documents Folder
                    try fileManager.copyItem(atPath: inboxFolderPath + "/" + hgtFileWithoutDash, toPath: documentsFolderPath[0] + "/" + hgtFileWithoutDash)
                    do {
                        // delete the import file in the Input folder.
                        try fileManager.removeItem(atPath: inboxFolderPath + "/" + hgtFileName)
                    }
                    catch let error as NSError {
                        print("Error deleting the " + hgtFileName + " HGT file after the import: \(error)")
                    }
                }
                catch let error as NSError {
                    print("Error: \(error)")
                }
            } else {
                // file already exists in the Documents folder
                // delete the file without copying it.
                do {
                    // delete the import file in the Input folder.
                    try fileManager.removeItem(atPath: inboxFolderPath + "/" + hgtFileName)
                }
                catch let error as NSError {
                    print("Error deleting the " + hgtFileName + " HGT file after the import: \(error)")
                }
            }
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }
    
    
    // MARK: - Core Data stack
    
    
    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "mil.nga.giat.fogmachine" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "FogMachine", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("FogMachine.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator!.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch var error1 as NSError {
            error = error1
            coordinator = nil
            // Report any error we got.
            var errorValues = [AnyHashable: Any]()
            errorValues[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data."
            errorValues[NSLocalizedFailureReasonErrorKey] = failureReason
            errorValues[NSUnderlyingErrorKey] = error
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: errorValues)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(String(describing: error)), \(String(describing: error?.userInfo))")
            abort()
        } catch {
            fatalError()
        }
        
        return coordinator
    }()
    
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    
    // MARK: - Core Data Saving support
    
    
    func saveContext () {
        if let moc = self.managedObjectContext {
            if moc.hasChanges {
                do {
                    try moc.save()
                } catch let error as NSError {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    NSLog("Unresolved error \(error), \(error.userInfo)")
                    abort()
                }
            }
        }
    }
    

}

