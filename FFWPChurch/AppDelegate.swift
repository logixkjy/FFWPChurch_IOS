//
//  AppDelegate.swift
//  FFWPChurch
//
//  Created by JooYoung Kim on 2023/08/04.
//

import UIKit
import objcModule
import KakaoSDKAuth
import KakaoSDKCommon
import FBSDKCoreKit
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import FirebaseMessaging

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let gcmMessageIDKey = "gcm.message_id"
    
    public var avVideoPlayer: FFAVPlayerViewController? = nil
    public var avAudioPlayer: STKAudioPlayer? = nil
    
    var orientationLock = UIInterfaceOrientationMask.all
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return self.orientationLock
    }

    struct AppUtility {
        static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
            if let delegate = UIApplication.shared.delegate as? AppDelegate {
                delegate.orientationLock = orientation
            }
        }

        static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation:UIInterfaceOrientation) {
            self.lockOrientation(orientation)
            UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
        }
    }
    func handleOpenURL(url : URL) -> Bool {
        let sz_url = url.absoluteString
        if sz_url.hasPrefix(DIRECT_URL_KEY) {
            let schemeCallback = directURLParsing(urlString: sz_url)
            if schemeCallback!["func"] == "churchffwpext" {
                if DataCenter.shared.isLoadMainView == false {
                    DataCenter.shared.schemeData = schemeCallback!
                } else {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "cmdDicOpenURLNotification"), object: nil, userInfo: schemeCallback)
                }
                
                return true
            }
        }
        return false
    }
    
    func directURLParsing(urlString: String) -> [String:String]? {
        let newUrlString = (urlString as NSString).removingPercentEncoding
        
        let funcPrefixRange = (newUrlString! as NSString).range(of: "churchffwpapp://", options: [.caseInsensitive, .backwards])
        
        if funcPrefixRange.location != NSNotFound {
            var function = ""
            var param: Dictionary<String, String> = [:]
            
            let webAPI = (newUrlString! as NSString).substring(from: funcPrefixRange.location+funcPrefixRange.length)
            let separatedIndex = (webAPI as NSString).range(of: "?").location
            if separatedIndex != NSNotFound {
                
                function = (webAPI as NSString).substring(to: separatedIndex)
                if function.count > 0 {
                    param.updateValue(function, forKey: "func")
                }
                
                let paramList = (webAPI as NSString).substring(from: separatedIndex+1).components(separatedBy: "&")
                for paramData in paramList {
                    let temp = paramData.components(separatedBy: "=")
                    if temp.count == 2 {
                        param.updateValue(temp[1], forKey: temp[0])
                    }
                }
            } else {
                if webAPI.count > 0 {
                    param.updateValue(webAPI, forKey: "func")
                }
            }
            
            if param.count > 0 {
                return param
            }
        }
        
        return nil;
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // 외부 링크 호출
        if handleOpenURL(url: url) {
            return true
        }
        // 카카오 로그인
        if (AuthApi.isKakaoTalkLoginUrl(url)) {
            return AuthController.handleOpenUrl(url: url)
        }
        // 페이스북 로그인
        ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
        // 구글 로그인
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // 카카오 로그인
        KakaoSDK.initSDK(appKey: "d9c9e8ab30a969584e60c4d3373c40e7")
        
        // 페이스북 로그인
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        // 구글 로그인 /푸시
        FirebaseApp.configure()
        
        // [START set_messaging_delegate]
        Messaging.messaging().delegate = self
        // [END set_messaging_delegate]
        
        // Register for remote notifications. This shows a permission dialog on first run, to
        // show the dialog at a more appropriate time move this registration accordingly.
        // [START register_for_notifications]
        
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
        )
        
        application.registerForRemoteNotifications()
        
        // [END register_for_notifications]
        
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    // [START receive_message]
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async
    -> UIBackgroundFetchResult {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        return UIBackgroundFetchResult.newData
    }
    
    // [END receive_message]
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }
    
    // This function is added here only for debugging purposes, and can be removed if swizzling is enabled.
    // If swizzling is disabled then this function must be implemented so that the APNs token can be paired to
    // the FCM registration token.
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("APNs token retrieved: \(deviceToken)")
        
        // With swizzling disabled you must set the APNs token here.
        // Messaging.messaging().apnsToken = deviceToken
    }
    
    func onPushAction(userInfo : Dictionary<AnyHashable, Any>) {
        if DataCenter.shared.isLoadMainView {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "cmdDidPushAcionNotification"), object:nil, userInfo:userInfo)
        } else {
            DataCenter.shared.userInfo = userInfo
        }
    }
    
    func requestTokenSave(appToken: String, Completion: @escaping (_ success: Bool) -> Void) {
        guard let dictionary = Bundle.main.infoDictionary,
              let version = dictionary["CFBundleShortVersionString"] as? String
        else { return }
        
        var params: [String : String] = [:]
        params.updateValue("ios", forKey: "os")
        params.updateValue(version, forKey: "version")
        params.updateValue(appToken, forKey: "token")
        
        let urlValue: String = TOKEN_URL
        var urlRequest = URLRequest(url: NSURL(string: urlValue)! as URL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: TIME_OUT_INTERVAL)
        
        do {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
        } catch let error {
            print(error.localizedDescription)
            
            return
        }
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let result = data {
                if let resultString = NSString.init(data: result, encoding: NSUTF8StringEncoding) {
                    if resultString.contains("true") {
                        Completion(true)
                        return
                    }
                }
            }
            Completion(false)
        }.resume()
    }
}

extension AppDelegate: MessagingDelegate {
    // [START refresh_token]
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.

        if let curToken = DataCenter.readObjectFromDefault("FCM_TOKEN") as? String {
            if curToken != fcmToken {
                DataCenter.writeObjectToDefault(fcmToken as Any, "FCM_TOKEN")
                self.requestTokenSave(appToken: fcmToken!) { success in
                    
                }
            }
        }

        Messaging.messaging().subscribe(toTopic: "IOS")
        Messaging.messaging().subscribe(toTopic: "IOSadmin​")
    }
    
    // [END refresh_token]
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async
    -> UNNotificationPresentationOptions {
        let userInfo = notification.request.content.userInfo
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // [START_EXCLUDE]
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        // [END_EXCLUDE]
        
        // Print full message.
        print(userInfo)
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "cmdDidPushAcionNotificationForeground"), object: nil, userInfo: userInfo)
        
        // Change this to your preferred presentation option
        return [[.alert, .sound]]
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        
        // [START_EXCLUDE]
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        // [END_EXCLUDE]
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print full message.
        print(userInfo)
        self.onPushAction(userInfo: userInfo)
    }
}
