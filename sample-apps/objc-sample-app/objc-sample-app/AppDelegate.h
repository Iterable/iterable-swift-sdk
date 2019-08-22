//
//  AppDelegate.h
//  objc-sample-app
//
//  Created by Tapash Majumder on 6/21/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>

@import IterableSDK;

@interface AppDelegate: UIResponder <UIApplicationDelegate, UNUserNotificationCenterDelegate, IterableURLDelegate, IterableCustomActionDelegate>

@property (strong, nonatomic) UIWindow *window;

@end
