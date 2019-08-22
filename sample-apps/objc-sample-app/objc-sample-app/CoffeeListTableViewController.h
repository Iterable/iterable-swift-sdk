//
//  CoffeeListTableViewController.h
//  objc-sample-app
//
//  Created by Tapash Majumder on 6/21/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CoffeeListTableViewController: UITableViewController<UISearchControllerDelegate, UISearchResultsUpdating>

@property (nonatomic, copy) NSString *searchTerm;

@end
