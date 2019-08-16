//
//  CoffeeListTableViewController.m
//  objc-sample-app
//
//  Created by Tapash Majumder on 6/21/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

#import "CoffeeListTableViewController.h"
#import "CoffeeType.h"
#import "CoffeeViewController.h"

@import IterableSDK;

@interface CoffeeListTableViewController ()

@property (nonatomic, strong, readonly) NSArray *coffeeList;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *loginOutBarButton;

@end

@implementation CoffeeListTableViewController

- (void)setSearchTerm:(NSString *)searchTerm {
    _searchTerm = searchTerm;
    if (_searchTerm != nil && _searchTerm.length > 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            searchController.searchBar.text = searchTerm;
            [searchController.searchBar becomeFirstResponder];
            [searchController becomeFirstResponder];
        });
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initializeCoffees];
    
    searchController = [[UISearchController alloc] initWithSearchResultsController: nil];
    searchController.searchBar.placeholder = @"Search";
    searchController.delegate = self;
    searchController.searchResultsUpdater = self;
    self.navigationItem.searchController = searchController;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    
    if (IterableAPI.email == nil) {
        self.loginOutBarButton.title = @"Login";
    } else {
        self.loginOutBarButton.title = @"Logout";
    }
}

#pragma mark - TableViewDataSource Functions
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.coffeeList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"coffeeCell" forIndexPath:indexPath];

    CoffeeType *coffee = self.coffeeList[indexPath.row];
    cell.textLabel.text = coffee.name;
    cell.imageView.image = coffee.image;
    
    return cell;
}

#pragma mark - Handlers
- (IBAction)loginOutButtonTapped:(UIBarButtonItem *)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"LoginNavController"];
    [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
    if (indexPath != nil) {
        CoffeeViewController *coffeeVC = (CoffeeViewController *) segue.destinationViewController;
        if (coffeeVC != nil) {
            coffeeVC.coffeeType = self.coffeeList[indexPath.row];
        }
    }
}

#pragma mark - UISearchControllerDelegate
- (void)willDismissSearchController:(UISearchController *)searchController {
    self.searchTerm = nil;
}

#pragma mark - UISearchResultsUpdating
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *text = searchController.searchBar.text;
    if (text != nil && text.length > 0) {
        filtering = true;
        filteredCoffees = [coffees filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.name contains[c] %@", text]];
    } else {
        filtering = false;
    }
    
    [self.tableView reloadData];
}

#pragma mark - private
UISearchController *searchController;
bool filtering = false;

NSArray *coffees;
NSArray *filteredCoffees;

- (void) initializeCoffees {
    coffees = @[CoffeeType.cappuccino, CoffeeType.latte, CoffeeType.mocha, CoffeeType.black];
    
    filteredCoffees = @[];
}

- (NSArray *) coffeeList {
    return filtering ? filteredCoffees : coffees;
}

@end
