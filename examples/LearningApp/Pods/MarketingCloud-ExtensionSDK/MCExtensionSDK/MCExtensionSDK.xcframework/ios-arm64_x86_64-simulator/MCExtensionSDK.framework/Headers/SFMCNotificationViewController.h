//
//  SFMCNotificationViewController.h
//  MCExtensionSDK
//
//  Created on 25/11/24.
//  Copyright © 2024 Salesforce Marketing Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

/// :nodoc:
extern const NSTimeInterval defaultRequestTimeout;

@class SFMCContentExtensionConfig;

/// The base class for notification content extensions.
///
/// The notification content extension principal class should inherit from `SFMCNotificationViewController`.
///
/// @note `SFMCNotificationViewController` fully manages UI rendering.
/// **Do not implement or override** any `UIViewController` methods in the principal class
/// of the content extension, as doing so may interfere with UI rendering.
@interface SFMCNotificationViewController : UIViewController

NS_ASSUME_NONNULL_BEGIN
/// Override and implement this method to provide custom configuration, if needed. @see SFContentExtensionConfig.
/// @return the custom configuration that needs to set for content extension.
- (SFMCContentExtensionConfig *)sfmcProvideConfig;
NS_ASSUME_NONNULL_END

@end
