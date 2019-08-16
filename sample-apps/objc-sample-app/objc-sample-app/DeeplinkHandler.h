//
//  DeeplinkHandler.h
//  objc-sample-app
//
//  Created by Tapash Majumder on 6/21/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DeeplinkHandler: NSObject

+ (BOOL)handleURL:(NSURL *)url;

@end
