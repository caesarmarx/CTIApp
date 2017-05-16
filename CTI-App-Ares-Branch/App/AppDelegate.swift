//
//  AppDelegate.swift
//  CTI Translators
//
//  Created by Adeo
//  Copyright © 2016 CTI. All rights reserved.
//

import UIKit
import CoreData
import Firebase
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



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        // Customize navigation bar
        let attrs = [
            NSForegroundColorAttributeName: UIColor(red: 0, green: 0, blue: 0, alpha: 1),
            NSFontAttributeName: UIFont.systemFont(ofSize: 16)
        ]
        
        UINavigationBar.appearance().titleTextAttributes = attrs
        UINavigationBar.appearance().tintColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        
        //Push notifications
        registerForPushNotifications(application)
        FIRApp.configure()

        
        // Override point for customization after application launch.
        let settings = UserDefaults.standard
        
////////////    DELETE PREFERENCES' USER ///////////////
        //settings.removeObjectForKey("user")
        //settings.removeObjectForKey("password")
        //settings.removeObjectForKey("profile")
        //settings.removeObjectForKey("session")
        //settings.synchronize()
        
        /*******    GET USER AND PASSWORD TO AUTH    ********/
        let user = settings.string(forKey: "user")
        let pass = settings.string(forKey: "password")
        let deviceToken = settings.string(forKey: "deviceToken")
        
        /*******    USER LOGED    *******/
        if user != nil && pass != nil
        {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            let home = storyboard.instantiateViewController(withIdentifier: "home") as! UITabBarController
            
            self.window?.rootViewController = home
            self.window?.makeKeyAndVisible()
            
            UIApplication.shared.setMinimumBackgroundFetchInterval(60)
        }
        
        if deviceToken == nil {
            
            let settings = UserDefaults.standard
            #if (arch(i386) || arch(x86_64)) && (os(iOS) || os(watchOS) || os(tvOS))
                settings.set(UUID().uuidString, forKey:"deviceToken")
                settings.synchronize()
            #endif
            settings.set(UUID().uuidString, forKey:"deviceToken")
            settings.synchronize()

        }
        
        //ACTION TO CLOSE THE NOTIFICATION OF "NEED MORE TIME?"
        let not_more = UIMutableUserNotificationAction()
        not_more.identifier="not_more"
        not_more.title = "No"
        not_more.activationMode = .background
        not_more.isAuthenticationRequired = false
        not_more.isDestructive = true
        
        //ACTION TO REQUEST MORE TIME "NEED MORE TIME?"
        let more = UIMutableUserNotificationAction()
        more.identifier = "more"
        more.title = "Yes"
        more.activationMode = .foreground
        more.isAuthenticationRequired = false
        more.isDestructive = false
        
        //CREATE ACTION TO ALERTS OF "NEED MORE TIME?"
        let timeclock_not = UIMutableUserNotificationCategory()
        timeclock_not.identifier = "Timeclock"
        timeclock_not.setActions([not_more, more], for: .default)
        timeclock_not.setActions([not_more, more], for: .minimal)
        application.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: [timeclock_not]))
        
        //handler of push notifications
        if let notification = launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] as? [String: AnyObject]
        {
            //Get object
            let job = notification["aps"] as! [String: AnyObject]
            
            self.showNotification(job)
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
//        _ =  Scheduling()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
//        _ =  Scheduling()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    // MARK: - Core Data stack
    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "local.test_cti" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        //print("directory: \(urls[urls.count-1])")
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "databaseLocal", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true])
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
    
    //LOCAL NOTIFICATION
    func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, for notification: UILocalNotification, completionHandler: @escaping () -> Void) {
        
        //////ACTIONS OF THE LOCAL NOTIFICATION
        let condition = NSPredicate(format: "id == %@", argumentArray: [notification.userInfo!["tc"] as! Int!])
        let getTc = NSFetchRequest<NSFetchRequestResult>(entityName: "Timeclock")
        getTc.predicate = condition
        getTc.fetchLimit = 1
        
        ////GET THE TIMECLOCK ASSOCIATED TO THE NOTIFICATION
        do
        {
            let tc_searched = try self.managedObjectContext.fetch(getTc) as! [Timeclock]
            if tc_searched.count > 0
            {
                //print(tc_searched.first)
                let tc = tc_searched.first
                
                switch (identifier!)
                {
                    case "not_more":
                        LocalNotification.sharedInstance.removeNotification(tc!)
                    case "more":
                        LocalNotification.sharedInstance.removeNotification(tc!)
                        
                        //Make calling
                        if notification.alertBody == "Your request is nearly over, please call this number if you need an extension"
                        {
                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                            let vc = storyboard.instantiateViewController(withIdentifier: "5minutes") as! Alert5ViewController
                            vc.tc = tc!
                            UIApplication.topViewController()?.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
                        }
                        //Ask more time
                        else
                        {
                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                            let vc = storyboard.instantiateViewController(withIdentifier: "10minutes") as! Alert10ViewController
                            vc.tc = tc!
                            UIApplication.topViewController()?.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
                        }
                    default: // switch statements must be exhaustive - this condition should never be met
                        print("Error: unexpected notification action identifier!")
                }
            }
        }
        catch
        {
            print("ERROR searching")
        }
        
        
        completionHandler() // per developer documentation, app will terminate if we fail to call this
    }
    //MARK: -FETCH BACKGROUND
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        _ =  Scheduling()
    }
    
    //PUSH NOTIFICATIONS
    func registerForPushNotifications(_ application: UIApplication) {
        let notificationSettings = UIUserNotificationSettings(
            types: [.badge, .sound, .alert], categories: nil)
        application.registerUserNotificationSettings(notificationSettings)
    }
    
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        if notificationSettings.types != UIUserNotificationType()
        {
            application.registerForRemoteNotifications()
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        let tokenChars = (deviceToken as NSData).bytes.bindMemory(to: CChar.self, capacity: deviceToken.count)
        var tokenString = ""
        
        for i in 0..<deviceToken.count {
            tokenString += String(format: "%02.2hhx", arguments: [tokenChars[i]])
        }
        
        
        let settings = UserDefaults.standard
        settings.set(tokenString, forKey:"deviceToken")
        settings.synchronize()
        
        #if (arch(i386) || arch(x86_64)) && (os(iOS) || os(watchOS) || os(tvOS))
            settings.set(UUID().uuidString, forKey:"deviceToken")
            settings.synchronize()
        #endif

        // #Debug: print device token
//        let alert = AlertController().alertError(tokenString,msg: "Please verify your code and try again",opt: "Accept")
//        (window!.rootViewController as UIViewController!).present(alert, animated: true, completion: nil)
        
        //print("Device Token:", tokenString)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        /*let settings = NSUserDefaults.standardUserDefaults()
        settings.setObject("PRUEBA", forKey:"deviceToken")
        settings.synchronize()*/
        print("Failed to register:", error)
    }
    
    //Push while running
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any])
    {
        //Get object
        let job = userInfo["aps"] as! [String: AnyObject]
            
        self.showNotification(job)
    }
    
    func showNotification(_ job: [String: AnyObject])
    {
        print(job)
        
        if (job["view"] != nil)
        {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            let user = UserDefaults.standard.string(forKey: "user")
            let pass = UserDefaults.standard.string(forKey: "password")
            
            if user == nil || pass == nil {
                return
            }
            
            if job["view"] as! String == "detail_request"
            {
                let vc = storyboard.instantiateViewController(withIdentifier: job["view"] as! String) as! RequestViewController
                
                vc.request = Job(data: job as NSDictionary)
                vc.status = job["status"] as! Int
                
                if UIApplication.topViewController()?.navigationController != nil {
                    UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
                }
            }
            else if job["view"] as! String == "chat_msg"
            {
                let vc = storyboard.instantiateViewController(withIdentifier: job["view"] as! String) as! MessagesViewController
                vc.receiver = Contact(number: Int(job["from"] as! String)!, nameContact: job["name_from"] as! String, entity: job["entity"] as! String)
                
                if UIApplication.topViewController()?.navigationController != nil {
                    UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
                }
            }
            else if job["view"] as! String == "more_time"
            {
                let vc = storyboard.instantiateViewController(withIdentifier: job["view"] as! String) as! AlertTimeController
                vc.interpreter = (job["name_from"] as! String)
                vc.job = job["job"] as! NSNumber
                vc.inte = job["int"] as! NSNumber
                
                UIApplication.topViewController()?.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
            }
            else if job["view"] as! String == "response_time"
            {
                let vc = storyboard.instantiateViewController(withIdentifier: job["view"] as! String) as! ResponseViewController
                vc.time = job["time"] as! NSNumber
                vc.job = job["job"] as! NSNumber
                
                UIApplication.topViewController()?.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
            }
        }
    }
}

