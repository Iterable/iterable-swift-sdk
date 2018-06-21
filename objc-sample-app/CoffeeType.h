//
//  CoffeeType.h
//  objc-sample-app
//
//  Created by Tapash Majumder on 6/21/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CoffeeType : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) UIImage *image;

- (instancetype) initWithName:(NSString *)name andImage:(UIImage *)image;
@end
