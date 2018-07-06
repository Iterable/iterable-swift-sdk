//
//  CoffeeViewController.h
//  objc-sample-app
//
//  Created by Tapash Majumder on 6/21/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoffeeType.h"

@interface CoffeeViewController : UIViewController
@property (nonatomic) CoffeeType *coffeeType;
@property (weak, nonatomic) IBOutlet UILabel *coffeeLbl;
@property (weak, nonatomic) IBOutlet UIImageView *coffeeImageView;

@end
