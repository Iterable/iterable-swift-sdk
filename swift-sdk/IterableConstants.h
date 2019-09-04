//
//  IterableConstants.h
//
//  Created by David Truong on 9/9/16.
//  Copyright © 2016 Iterable. All rights reserved.
//

@interface IterableConstants: NSObject

@end

//typedef void (^ITEActionBlock)(NSString *_Nullable);

//typedef void (^ITBURLCallback)(NSURL *_Nullable);

/**
 The prototype for the completion handler block that gets called when an Iterable call is successful
 */
//typedef void (^OnSuccessHandler)(NSDictionary * _Nullable data);

/**
 The prototype for the completion handler block that gets called when an Iterable call fails
 */
//typedef void (^OnFailureHandler)(NSString * _Nullable reason, NSData *_Nullable data);

/* Swift equivalents (for when ready to move to 100% Swift */
// typealias ITEActionBlock = (String?) -> Void
// typealias ITBURLCallback = (URL?) -> Void
// typealias OnSuccessHandler = (_ data: Dictionary<AnyHashable, Any>?) -> Void
// typealias OnFailureHandler = (_ reason: String?, _ data: Data?) -> Void
