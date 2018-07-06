//
//  AppDelegate.m
//  objc-sample-app
//
//  Created by Tapash Majumder on 6/21/18.
//  Copyright © 2018 Iterable. All rights reserved.
//


#import "AppDelegate.h"
#import "DeeplinkHandler.h"

@import IterableSDK;

@interface AppDelegate ()
@end

@implementation AppDelegate
// IMP: Either email or userId must be set.
NSString *apiKey = @""; // set iterable api key here
NSString *email = @""; // set iterable email here
NSString *userId = @"";// set iterable userId here, either email or userId must be set


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // initial check
    if (apiKey.length == 0 || (email.length == 0 && userId.length == 0)) {
        [NSException raise:@"Not Initialized" format:@"Iterable API key and either email or userId must be set."];
    }
    
    //ITBL: Setup Notifications
    [self setupNotifications];
    
    //ITBL: Initialize API
    IterableConfig *config = [[IterableConfig alloc] init];
    config.urlDelegate = self;
    config.customActionDelegate = self;
    config.pushIntegrationName = @"objc-sample-app";
    config.sandboxPushIntegrationName = @"objc-sample-app";
    
    [IterableAPI initializeWithApiKey: apiKey
                           launchOptions:launchOptions
                                  config:config];
    IterableAPI.sharedInstance.email = email;
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Url handling
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler {
    
    //ITBL:
    NSURL *url = userActivity.webpageURL;
    if (url == nil) {
        return NO;
    }
    
    return [IterableAPI handleUniversalLink:url];
}

#pragma mark - notification registration
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [IterableAPI.sharedInstance registerToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    //TODO: handle
}

#pragma mark - UNUserNotificationCenterDelegate
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    completionHandler (UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionSound);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    [IterableAppIntegration userNotificationCenter:center didReceive:response withCompletionHandler:completionHandler];
}

#pragma mark - IterableURLDelegate
// return true if we handled the url
- (BOOL)handleIterableURL:(NSURL *)url context:(IterableActionContext *)context {
    return [DeeplinkHandler handleURL:url];
}

#pragma mark - IterableCustomActionDelegate
// handle the cutom action from push
// return value true/false doesn't matter here, stored for future use
- (BOOL)handleIterableCustomAction:(IterableAction *)action context:(IterableActionContext *)context {
    if ([action.type isEqualToString:@"handleFindCoffee"]) {
        if (action.userInput != nil) {
            NSString *urlString = [[NSString alloc] initWithFormat:@"https://majumder.me/coffee?q=%@", action.userInput];
            NSURL *url = [[NSURL alloc] initWithString:urlString];
            return [DeeplinkHandler handleURL:url];
        }
    }

    return FALSE;
}

#pragma mark - private
//ITBL:
// Ask for permission for notifications etc.
// setup self as delegate to listen to push notifications.
- (void) setupNotifications {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;
    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        if (settings.authorizationStatus != UNAuthorizationStatusAuthorized) {
            // not authorized, ask for permission
            [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionSound) completionHandler:^(BOOL granted, NSError * _Nullable error) {
                if (granted) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [UIApplication.sharedApplication registerForRemoteNotifications];
                    });
                } // TODO: handle errors
            }];
        } else {
            // already authorized
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIApplication.sharedApplication registerForRemoteNotifications];
            });
        }
    }];
}

@end
