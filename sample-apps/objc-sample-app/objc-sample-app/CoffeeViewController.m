//
//  CoffeeViewController.m
//  objc-sample-app
//
//  Created by Tapash Majumder on 6/21/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

#import "CoffeeViewController.h"

@import IterableSDK;

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
    if (self.coffeeType != nil) {
        IterableAttributionInfo *attributionInfo = IterableAPI.attributionInfo;
        NSDictionary *dataFields;
        if (attributionInfo != nil) {
            dataFields = @{@"campaignId": attributionInfo.campaignId,
                           @"templateId": attributionInfo.templateId,
                           @"messageId": attributionInfo.messageId
                           };
        } else {
            dataFields = @{};
        }
        
        NSNumber *price = [[NSNumber alloc] initWithDouble:10.0];
        CommerceItem *item = [[CommerceItem alloc]
                              initWithId:self.coffeeType.name.lowercaseString name:self.coffeeType.name price:price quantity:1 sku:nil description:nil url:nil imageUrl:nil categories:nil dataFields:nil];
        [IterableAPI trackPurchase:price items:@[item] dataFields:dataFields];
    }
}

- (IBAction)cancelButtonTap:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:true];
}

@end
