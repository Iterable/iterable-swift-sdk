//
//  CoffeeListTableViewController.m
//  objc-sample-app
//
//  Created by Tapash Majumder on 6/21/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

#import "CoffeeListTableViewController.h"
#import "CoffeeType.h"

@interface CoffeeListTableViewController ()
@end

@implementation CoffeeListTableViewController

- (void)setSearchTerm:(NSString *)searchTerm {
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initializeCoffees];
    
    searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    searchController.searchBar.placeholder = @"Search";
    self.navigationItem.searchController = searchController;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return coffees.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"coffeeCell" forIndexPath:indexPath];

    CoffeeType *coffee = coffees[indexPath.row];
    cell.textLabel.text = coffee.name;
    cell.imageView.image = coffee.image;
    
    return cell;
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
}

#pragma mark - private
UISearchController *searchController;

NSArray *coffees;

- (void) initializeCoffees {
    CoffeeType *cappuccino = [[CoffeeType alloc] initWithName:@"Cappuccino" andImage: [UIImage imageNamed:@"Cappuccino"]];
    CoffeeType *latte = [[CoffeeType alloc] initWithName:@"Latte" andImage: [UIImage imageNamed:@"Latte"]];
    CoffeeType *mocha = [[CoffeeType alloc] initWithName:@"Mocha" andImage: [UIImage imageNamed:@"Mocha"]];
    CoffeeType *black = [[CoffeeType alloc] initWithName:@"Black" andImage: [UIImage imageNamed:@"Black"]];

    coffees = @[cappuccino, latte, mocha, black];
}

@end
