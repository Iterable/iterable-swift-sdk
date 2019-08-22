//
//  LoginViewController.m
//  objc-sample-app
//
//  Created by Tapash Majumder on 7/18/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

#import "LoginViewController.h"
@import IterableSDK;

@interface LoginViewController ()

@property (weak, nonatomic) IBOutlet UITextField *emailAddressTextField;
@property (weak, nonatomic) IBOutlet UIButton *logInOutButton;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if (IterableAPI.email == nil) {
        self.emailAddressTextField.text = nil;
        self.emailAddressTextField.enabled = YES;
        [self.logInOutButton setTitle:@"Login" forState:UIControlStateNormal];
    } else {
        self.emailAddressTextField.text = IterableAPI.email;
        self.emailAddressTextField.enabled = NO;
        [self.logInOutButton setTitle:@"Logout" forState:UIControlStateNormal];
    }
}

- (IBAction)logInOutButtonTapped:(UIButton *)sender {
    if (IterableAPI.email == nil) {
        // login
        if (self.emailAddressTextField.text != nil && self.emailAddressTextField.text.length > 0) {
            IterableAPI.email = self.emailAddressTextField.text;
        }
    } else {
        // logout
        IterableAPI.email = nil;
    }
    [self.presentingViewController dismissViewControllerAnimated:true completion:nil];
}

- (IBAction)doneButtonTapped:(UIBarButtonItem *)sender {
    [self.presentingViewController dismissViewControllerAnimated:true completion:nil];
}
@end
