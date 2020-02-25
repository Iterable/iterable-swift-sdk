//
//  CoffeeType.m
//  objc-sample-app
//
//  Created by Tapash Majumder on 6/21/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

#import "CoffeeType.h"

@implementation CoffeeType
+ (CoffeeType *)cappuccino {
    static CoffeeType *cappuccinoCoffee = nil;
    
    if (cappuccinoCoffee == nil) {
        cappuccinoCoffee = [[CoffeeType alloc] initWithName:@"Cappuccino" andImage: [UIImage imageNamed: @"Cappuccino"]];
    }
    
    return cappuccinoCoffee;
}

+ (CoffeeType *)latte {
    static CoffeeType *latteCoffee = nil;
    
    if (latteCoffee == nil) {
        latteCoffee = [[CoffeeType alloc] initWithName:@"Latte" andImage: [UIImage imageNamed: @"Latte"]];
    }
    
    return latteCoffee;
}

+ (CoffeeType *)mocha {
    static CoffeeType *mochaCoffee = nil;
    
    if (mochaCoffee == nil) {
        mochaCoffee = [[CoffeeType alloc] initWithName:@"Mocha" andImage: [UIImage imageNamed: @"Mocha"]];
    }
    
    return mochaCoffee;
}

+ (CoffeeType *)black {
    static CoffeeType *blackCoffee = nil;
    
    if (blackCoffee == nil) {
        blackCoffee = [[CoffeeType alloc] initWithName:@"Black" andImage: [UIImage imageNamed: @"Black"]];
    }
    
    return blackCoffee;
}

- (instancetype)initWithName:(NSString *)name andImage:(UIImage *)image {
    if (self = [super init]) {
        self.name = name;
        self.image = image;
    }
    
    return self;
}

@end
