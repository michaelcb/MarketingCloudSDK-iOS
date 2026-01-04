//
//  SFMCNotificationService.h
//  MCExtensionSDK
//
//  Created on 12/11/24.
//  Copyright © 2024 Salesforce Marketing Cloud. All rights reserved.
//

#import <UserNotifications/UserNotifications.h>


@class SFMCNotificationServiceConfig;

/// The primary class for handling notification service extensions.
/// `SFMCNotificationService` should be used as the base class for
/// notification service extensions.
///
/// @note **Important:** Do not implement any `UNNotificationServiceExtension` methods, including:
/// - `didReceive(_:withContentHandler:)`
/// - `serviceExtensionTimeWillExpire()`
///
/// Implementing these methods may interfere with the expected behavior
/// of `SFMCNotificationService`, potentially leading to unexpected issues.
@interface SFMCNotificationService : UNNotificationServiceExtension

NS_ASSUME_NONNULL_BEGIN

/// Override and implement this method to provide custom configuration option.
/// The default implementation provides a logging level configruration option of `.none` @see LogLevel.
- (SFMCNotificationServiceConfig *)sfmcProvideConfig;

/// Processes incoming push notifications and allows custom modifications.
///
/// Override this method to customize push notification handling, such as:
/// - **Enabling/Disabling logging** and adjusting log levels.
/// - **Downloading and attaching media** (images, videos) to the notification.
/// - **Adding custom key-value pairs** to `userInfo` in the push payload.
/// - **Performing other necessary operations** based on business requirements.
///
/// @param request The original notification request.
/// @param mutableContent A mutable notification content object that can be modified.
/// @param contentHandler A completion handler that must be called with the modified content.
///
/// @note **Important Considerations:**
/// - **Do not modify** `mutableContent.request.content.userInfo` directly, as it may cause an exception.
///   Instead, pass custom key-value pairs via `contentHandler`, e.g.,
///   `contentHandler(@{@"customKey": @"customValue"})`.
/// - **Limited execution time:** The notification service extension has a restricted execution window,
///   so keep your custom processing as short as possible.
/// - **Always call the completion handler** in every possible execution path to avoid timeouts.
- (void)sfmcDidReceiveRequest:(UNNotificationRequest *)request
               mutableContent:(UNMutableNotificationContent *)mutableContent
           withContentHandler:(void (^)(NSDictionary * __nullable))contentHandler;

#ifdef EXTENSION_CUSTOM_HEADER
+ (SFMCNotificationService * _Nullable)currentInstance;
#endif

NS_ASSUME_NONNULL_END

@end


