//
//  UsersSelectionTableViewController.m
//  Dude
//
//  Created by Georges Kanaan on 15/03/2016.
//  Copyright © 2016 Georges Kanaan. All rights reserved.
//

#import "UsersSelectionTableViewController.h"

// Managers
#import "ContactsManager.h"

// Models
#import "DUser.h"

// Pods
#import <SDWebImage/UIImageView+WebCache.h>

// Extensions & Categories
#import "UIImageExtensions.h"

@interface UsersSelectionTableViewController () {
  NSMutableArray *selectedContacts;
  
  NSMutableSet *indexTitles;
  
  NSMutableDictionary *splittedContacts;
}

@end

@implementation UsersSelectionTableViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  // Add done button
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];

  
  // get contacts, sort, filter and save them
  NSArray *contacts = [[[ContactsManager sharedInstance] getContactsRefreshedNecessary:NO favourites:NO] allObjects];
  selectedContacts = [NSMutableArray arrayWithArray:[self.composeSheetViewController.selectedUsers allObjects]];
  
  NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"fullName" ascending:YES selector:@selector(caseInsensitiveCompare:)];
  [contacts sortedArrayUsingDescriptors:@[sort]];
  
  splittedContacts = [NSMutableDictionary new];
  indexTitles = [NSMutableSet new];
  for (DUser *user in contacts) {
    NSString *firstLetter = [user.fullName substringToIndex:1];
    
    if ([indexTitles containsObject:firstLetter]) {
      NSMutableArray *existingArray = [NSMutableArray arrayWithArray:(NSArray*)(splittedContacts[firstLetter])];
      [existingArray addObject:user];
      
      [splittedContacts setObject:(NSArray*)existingArray forKey:firstLetter];
    
    } else {
      [indexTitles addObject:[user.fullName substringToIndex:1]];
      
      NSMutableArray *existingArray = [NSMutableArray arrayWithArray:(NSArray*)(splittedContacts[firstLetter])];
      [existingArray addObject:user];
      
      [splittedContacts setObject:(NSArray*)existingArray forKey:firstLetter];
    }
  }
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return indexTitles.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return ((NSArray*)splittedContacts[(NSString*)[indexTitles allObjects][section]]).count;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
  return [indexTitles allObjects];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
  return [[indexTitles allObjects] indexOfObject:title];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
  
  // Configure the cell
  DUser *user = ((NSArray*)splittedContacts[(NSString*)[indexTitles allObjects][indexPath.section]])[indexPath.row];
  cell.textLabel.text = user.fullName;
  
  [cell.imageView sd_setImageWithURL:[NSURL URLWithString:user.profileImage.url] placeholderImage:[UIImage imageNamed:@"Default Profile Image"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
    [cell.imageView setImage:[image resizedImage:CGSizeMake(50, 50) interpolationQuality:kCGInterpolationHigh]];
    [cell layoutSubviews];
  }];
  
  // Add checkmarck if user is already selected
  cell.accessoryType = ([selectedContacts containsObject:user]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
  
  return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  DUser *user = ((NSArray*)splittedContacts[(NSString*)[indexTitles allObjects][indexPath.section]])[indexPath.row];
  UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
  
  if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
    cell.accessoryType = UITableViewCellAccessoryNone;
    [selectedContacts removeObject:user];
    
  } else {
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    [selectedContacts addObject:user];
  }
}


#pragma mark - Navigation
- (IBAction)done {
  self.composeSheetViewController.selectedUsers = [NSSet setWithArray:selectedContacts];
  
  [self dismissViewControllerAnimated:YES completion:nil];
}

@end
