//
//  CoffeeViewController.m
//  objc-sample-app
//
//  Created by Tapash Majumder on 6/21/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

#import "CoffeeViewController.h"

@interface CoffeeViewController ()

@end

@implementation CoffeeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.coffeeType != nil) {
        self.coffeeLbl.text = self.coffeeType.name;
        self.coffeeImageView.image = self.coffeeType.image;
    }
}

#pragma mark action
- (IBAction)buyButtonTap:(UIButton *)sender {
    
}

- (IBAction)cancelButtonTap:(UIButton *)sender {
}

@end
