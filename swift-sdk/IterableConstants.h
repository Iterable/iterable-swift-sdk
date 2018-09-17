//
//  IterableConstants.h
//
//  Created by David Truong on 9/9/16.
//  Copyright © 2016 Iterable. All rights reserved.
//

@interface IterableConstants : NSObject

@end

typedef void (^ITEActionBlock)(NSString *);

typedef void (^ITBURLCallback)(NSURL *);

/**
 The prototype for the completion handler block that gets called when an Iterable call is successful
 */
typedef void (^OnSuccessHandler)(NSDictionary *data);

/**
 The prototype for the completion handler block that gets called when an Iterable call fails
 */
typedef void (^OnFailureHandler)(NSString *reason, NSData *_Nullable data);
