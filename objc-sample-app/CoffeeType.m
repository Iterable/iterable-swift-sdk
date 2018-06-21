//
//  CoffeeType.m
//  objc-sample-app
//
//  Created by Tapash Majumder on 6/21/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

#import "CoffeeType.h"

@implementation CoffeeType
- (instancetype) initWithName:(NSString *)name andImage:(UIImage *)image {
    if (self = [super init]) {
        self.name = name;
        self.image = image;
    }
    return self;
}
@end
