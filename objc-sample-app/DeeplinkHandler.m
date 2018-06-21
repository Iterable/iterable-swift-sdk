//
//  DeeplinkHandler.m
//  objc-sample-app
//
//  Created by Tapash Majumder on 6/21/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

#import "DeeplinkHandler.h"
#import "CoffeeType.h"
#import "CoffeeViewController.h"

@implementation DeeplinkHandler

+ (bool)handleURL:(NSURL *)url {
    if ([url.host  isEqualToString: @"iterable-sample-app.firebaseapp.com"]) {
        [DeeplinkHandler showURL:url];
        return true;
    } else if ([url.host isEqualToString:@"links.iterable.com"]) {
        return true;
    } else {
        return false;
    }
}

+ (void) showURL:(NSURL *)url {
    NSString *page = url.lastPathComponent.lowercaseString;
    if ([page isEqualToString:@"mocha"]) {
        [DeeplinkHandler showCoffee:CoffeeType.mocha];
    } else if ([page isEqualToString:@"latte"]) {
        [DeeplinkHandler showCoffee:CoffeeType.latte];
    } else if ([page isEqualToString:@"cappuccino"]) {
        [DeeplinkHandler showCoffee:CoffeeType.cappuccino];
    } else if ([page isEqualToString:@"black"]) {
        [DeeplinkHandler showCoffee:CoffeeType.black];
    } else if ([page isEqualToString:@"coffee"]) {
        
    } else {
        [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
    }
}

+ (void) showCoffee:(CoffeeType *)coffeeType {
    UINavigationController *rootNav = (UINavigationController *) UIApplication.sharedApplication.keyWindow.rootViewController;
    if (rootNav != nil) {
        [rootNav popToRootViewControllerAnimated:false];

        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        CoffeeViewController *viewController = (CoffeeViewController *) [storyboard instantiateViewControllerWithIdentifier:@"CoffeeViewController"];
        viewController.coffeeType = coffeeType;
        
        [rootNav pushViewController:viewController animated:true];
    }
}
@end
