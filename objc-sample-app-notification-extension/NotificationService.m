//
//  NotificationService.m
//  objc-sample-app-notification-extension
//
//  Created by Tapash Majumder on 6/21/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

#import "NotificationService.h"

@import IterableAppExtensions;

@interface NotificationService ()

@property (nonatomic, strong) ITBNotificationServiceExtension *baseExtension;

@end

@implementation NotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    
    self.baseExtension = [[ITBNotificationServiceExtension alloc] init];
    [self.baseExtension didReceiveNotificationRequest:request withContentHandler:contentHandler];
}

- (void)serviceExtensionTimeWillExpire {
    [self.baseExtension serviceExtensionTimeWillExpire];
}

@end
