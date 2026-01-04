//
//  SFMCClientCalling.h
//  MCExtensionSDK
//
//  Created on 12/11/24.
//  Copyright © 2024 Salesforce Marketing Cloud. All rights reserved.
//

#import <UserNotifications/UserNotifications.h>

@class SFMCNotificationServiceConfig;

@protocol _SFMC_Internal_ClientCalling <NSObject>

NS_ASSUME_NONNULL_BEGIN
- (void)callClientDidReceiveRequest:(UNNotificationRequest *)request
                     mutableContent:(UNMutableNotificationContent *)mutableContent
                 withContentHandler:(void (^)(NSDictionary * __nullable))contentHandler;

- (SFMCNotificationServiceConfig *)callClientSfmcProvideConfig;
NS_ASSUME_NONNULL_END

@end
