//
//  AppDelegate.swift
//  LearningApp
//
//  Created by Brian Criscuolo on 6/4/19.
//  Copyright © 2019 Salesforce. All rights reserved.
//

import UIKit
import MarketingCloudSDK
import PushFeatureSDK
/*Note: This app demonstrates SDK integration using the traditional AppDelegate-based lifecycle. For apps using SceneDelegate, the SDK initialization should remain in AppDelegate, with scene-specific UI setup moved to SceneDelegate. */

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    
    // The appID, accessToken and appEndpoint are required values for MarketingCloud SDK configuration.
    // See https://salesforce-marketingcloud.github.io/MarketingCloudSDK-iOS/get-started/apple.html for more information.
    
    let appID = "c7f2edd1-8ebd-4ba1-b7a4-798ad1247ea6"
    let accessToken = "x68CMTdhK8i6dYy7R02AVTms"
    let appEndpointURL = "https://mchdtq6jm2n96s52znnfxvvspyh0.device.marketingcloudapis.com/"
    let mid = "514024017"
    
    // Define features of MarketingCloud SDK your app will use.
    let inbox = true
    let location = true
    let pushAnalytics = true
    let markMessageReadOnInboxNotificationOpen = true
    
    // MobilePush SDK: REQUIRED IMPLEMENTATION
    @discardableResult
    
    func configureSFMCSdk() -> Bool {
        
        SFMCSdk.setLogger(logLevel: .debug)
        
        // Use the `MarketingCloudSdkConfigBuilder` to configure the MarketingCloud SDK. This gives you the maximum flexibility in SDK configuration.
        // The builder lets you configure the module parameters at runtime.
        guard let appUrl = URL(string: appEndpointURL) else {
            print("Invalid App Endpoint URL")
            return false
        }
        let engagementConfiguration = MarketingCloudSdkConfigBuilder(appId: appID)
            .setAccessToken(accessToken)
            .setMarketingCloudServerUrl(appUrl)
            .setDelayRegistrationUntilContactKeyIsSet(true) // default = false
            .setMid(mid)
            .setInboxEnabled(inbox)
            .setLocationEnabled(location)
            .setAnalyticsEnabled(pushAnalytics)
            .setMarkMessageReadOnInboxNotificationOpen(markMessageReadOnInboxNotificationOpen)
            .setApplicationControlsBadging(false)
            .build()
       
        // Set the completion handler to take action when module initialization is completed.
        let completionHandler: ((_ status: [ModuleInitStatus]) -> Void) = { [weak self] status in
            DispatchQueue.main.async {
                self?.handleSDKInitializationCompletion(status: status)
            }
        }
        
        let pushFeatureConfig = PushFeatureConfigBuilder()
            .setApplicationControlsBadging(true)
            .build()

#if DEBUG
        SFMCSdk.identity.edit { model in
            model.profileId = "v_mbunch+test2@adt.com"
            return model
        }
#endif
        
        SFMCSdk.initializeSdk(
            ConfigBuilder()
                .setEngagement(config: engagementConfiguration)
                .setPushFeature(config: pushFeatureConfig)
                .build()
                ,completion: completionHandler)
        
        return true
    }
    
    // MARK: - SDK Initialization Completion Handler
    
    private func handleSDKInitializationCompletion(status: [ModuleInitStatus]) {
        var allSuccessful = true
        
        for moduleStatus in status {
            print("Module: \(moduleStatus.moduleName.rawValue), Status: \(moduleStatus.initStatus.rawValue)")
            
            if moduleStatus.initStatus == .success {
                // Handle successful initialization for each module
                switch moduleStatus.moduleName {
                    case .engagement:
                        setupEngagement()
                        break
                case .pushFeature:
                    setupPushFeature()
                    break
                default:
                    break
                }
            } else {
                allSuccessful = false
                logModuleInitializationFailure(moduleName: moduleStatus.moduleName, status: moduleStatus.initStatus)
            }
        }
        if allSuccessful {
            print("SDK initialization completed successfully")
        } else {
            print("SDK initialization completed with errors - check logs above")
        }
    }
    
    private func logModuleInitializationFailure(moduleName: ModuleName, status: OperationResult) {
        print("❌ ERROR: \(moduleName.rawValue) failed to initialize with status: \(status)")
    }
    
    // MARK: - Module Setup Methods
    
    func setupEngagement() {
        
        // Enable in-app messaging
        MarketingCloudSdk.requestSdk { mp in
            mp?.setEventDelegate(self)
        }
        
        MarketingCloudSdk.requestSdk { mp in
            mp?.setRegistrationCallback { reg in
                mp?.unsetRegistrationCallback()
                print("Registration callback was called: \(reg)")
            }
        }
        
        MarketingCloudSdk.requestSdk { mp in
            mp?.startWatchingLocation()
        }
    }
    
    // PushFeature Setup
    func setupPushFeature() {
        PushFeature.requestSdk { pushFeature in
            DispatchQueue.main.async {
                pushFeature?.setURLHandlingDelegate(self)
            }
        }
        
        PushFeature.requestSdk { pushFeature in
            pushFeature?.setPushEnabled(pushEnabled: true)
        }
        
        // This checks both iOS system notification settings and SDK-level enablement
        PushFeature.requestSdk { pushFeature in
            let isPushEnabled = pushFeature?.isPushEnabled()
            print("Push enabled: \(String(describing: isPushEnabled))")
        }
        
        PushFeature.requestSdk { pushFeature in
            let userInfo = pushFeature?.notificationUserInfo()
            print("Last notification userInfo: \(String(describing: userInfo))")
        }
        
        DispatchQueue.main.async {
            
            UNUserNotificationCenter.current().delegate = self
            
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge], completionHandler: {(_ granted: Bool, _ error: Error?) -> Void in
                if error == nil {
                    if granted == true {
                        DispatchQueue.main.async {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                        // set up appointment reminder confirmation
                        let confirm = UNNotificationAction(identifier: "CONFIRM", title: "Confirm", options: [])
                        let confirmCategory = UNNotificationCategory(identifier: "CONFIRMATION", actions: [confirm], intentIdentifiers: [] , options: [])
                        UNUserNotificationCenter.current().setNotificationCategories([confirmCategory])
                    }
                }
            })
            
            print("requesting feature")
            PushFeature.requestSdk { pushFeature in
                pushFeature?.setPushEnabled(pushEnabled: true)
            }
            
            PushFeature.requestSdk { pushFeature in
                let isPushEnabled = pushFeature?.isPushEnabled()
                print("Post define Push enabled: \(String(describing: isPushEnabled))")
            }

        }
    }
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.configureSFMCSdk()
        setupWindow()
        return true
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        PushFeature.requestSdk { pushFeature in
            pushFeature?.setDeviceToken(deviceToken)
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(error)
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
            PushFeature.requestSdk { pushFeature in
                pushFeature?.setNotificationUserInfo(userInfo)
            }
            completionHandler(.newData)
    }
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:] ) -> Bool {
        
        guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
                let page = components.path else {
                print("Invalid URL")
                return false
            }
        if  page == "confirm" {
            let event = CustomEvent(name: "AppEvent", attributes: ["EventKey": "ApptConfirmed", "EventValue": "Confirmed"])
            SFMCSdk.track(event: event!)
            let confirmPage = ApptConfirmationViewController(msg: "Thanks for confirming your appt.")
            showViewController(controller: confirmPage)
            return true
        }
        return false
    }
    
    private func showViewController(controller: UIViewController){
        if let window = self.window, let rootViewController = window.rootViewController {
            var currentController = rootViewController
            while let presentController = currentController.presentedViewController {
                currentController = presentController
            }
            let nav = UINavigationController(rootViewController: controller)
            currentController.present(nav, animated: true, completion: nil)
        }
    }

    private func setupWindow() {
        window = UIWindow(frame: UIScreen.main.bounds)
        let viewController = HomeViewController()
        let navigationController = UINavigationController(rootViewController: viewController)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Tell the SDK about the notification
        PushFeature.requestSdk { pushFeature in
            pushFeature?.setNotificationResponse(response)
        }
        // Check your notification custom actions
        if response.actionIdentifier == "CONFIRM" {
            let event = CustomEvent(name: "AppEvent", attributes: ["EventKey": "key", "EventValue": "test"])
            SFMCSdk.track(event: event!)
        }
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (  UNNotificationPresentationOptions) -> Void) {

       
        var alertData: [String: Any] = [:]
        alertData["NotificationEventType"] = "Alert"
        alertData["title"] = notification.request.content.title
        alertData["body"] = notification.request.content.body
        alertData["subtitle"] = notification.request.content.subtitle
        alertData["category"] = notification.request.content.categoryIdentifier
        alertData["userInfo"] = notification.request.content.userInfo
        
        
        NotificationCenter.default.post(name: .NotificationEvent, object: nil, userInfo: alertData)
        completionHandler([.alert, .badge, .sound])
    }
    
} // end of class AppDelegate

// PushFeature SDK: REQUIRED IMPLEMENTATION
extension AppDelegate: URLHandlingDelegate {
    func sfmc_handleURL(_ url: URL, type: String) {
        print("Handling URL: \(url) Type: \(type)")
        var urlData: [String: Any] = [:]
        urlData["NotificationEventType"] = "ShowUrl"
        urlData["url"] = url
        urlData["type"] = type
        NotificationCenter.default.post(name: .NotificationEvent, object: nil, userInfo: urlData)
    }
}

extension AppDelegate: InAppMessageEventDelegate {
    func sfmc_shouldShow(inAppMessage message: [AnyHashable : Any]) -> Bool {
        print("message should show")
        return true
    }
    
    func sfmc_didShow(inAppMessage message: [AnyHashable : Any]) {
        // message shown
        print("message was shown")
    }
    
    func sfmc_didClose(inAppMessage message: [AnyHashable : Any]) {
        // message closed
        print("message was closed")
    }
}
