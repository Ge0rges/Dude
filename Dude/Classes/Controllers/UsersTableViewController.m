//
//  UsersTableViewController.m
//  Dude
//
//  Created by Georges Kanaan on 6/3/15.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

#import "UsersTableViewController.h"

// Classes
#import "AppDelegate.h"

// Pods
#import <SDWebImage/UIImageView+WebCache.h>
#import <SWTableViewCell/SWTableViewCell.h>

// Managers
#import "ContactsManager.h"
#import "MessagesManager.h"

// Controllers
#import "MessagesTableViewController.h"

@interface UsersTableViewController () <SWTableViewCellDelegate> {
  NSArray *contacts;
  NSMutableArray *selectedContacts;
  
  BOOL selectedFacebook;
  BOOL selectedTwitter;
}

@property (nonatomic) BOOL favoritesOnly;

@end

@implementation UsersTableViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
#warning TO DO: figure out when we should actually use this
  //[[DUser currentUser] renewCredentials];
  
  // Initialize the arrays
  selectedContacts = [NSMutableArray new];
  contacts = [NSArray new];
  
  // Set controller properties
  self.favoritesOnly = NO;
  
  // Load initial data
  [self performSelectorInBackground:@selector(reloadData) withObject:nil];
  
  // Update status bar
  [self setNeedsStatusBarAppearanceUpdate];

  // Set a timer to update the users every 5 minutes
  [NSTimer timerWithTimeInterval:300 target:self selector:@selector(reloadData) userInfo:nil repeats:YES];
  
  // Add device contacts
  [[ContactsManager sharedInstance] addDeviceContactsAndSendNotification:YES];
  
  // Add Next button to nav bar
  UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStyleDone target:self action:@selector(showMessages)];
  nextButton.enabled = NO;
  [self.navigationItem setRightBarButtonItem:nextButton];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  // Make sure the + button is removed
  if (self.favoritesOnly) {
    [self.navigationItem setLeftBarButtonItem:nil];
  
  } else {
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addContact)];
    [self.navigationItem setLeftBarButtonItem:addButton];
  }
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  // Tell the delegate we are the visible view
  AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  appDelegate.visibleViewController = self;

  BOOL shouldRefreshTwitter = [[NSUserDefaults standardUserDefaults] boolForKey:@"askTwitter"];
  BOOL shouldRefreshFacebook = [[NSUserDefaults standardUserDefaults] boolForKey:@"askFacebook"];
  
  if (shouldRefreshTwitter) {
    [[DUser currentUser] selectTwitterAccountWithCompletion:^(BOOL success, ACAccount *account, NSError *error) {
      if (shouldRefreshFacebook) {
        [[DUser currentUser] selectFacebookAccountWithCompletion:^(BOOL success, ACAccount *account, NSError *error) {
            [self performSelectorInBackground:@selector(reloadData) withObject:nil];
        }];
        
      } else {
          [self performSelectorInBackground:@selector(reloadData) withObject:nil];
      }
    }];
    
  } else if (shouldRefreshFacebook ) {
    [[DUser currentUser] selectFacebookAccountWithCompletion:^(BOOL success, ACAccount *account, NSError *error) {
        [self performSelectorInBackground:@selector(reloadData) withObject:nil];
    }];
  }
}

#pragma mark - Public Methods
- (IBAction)reloadData {
  [self.refreshControl performSelectorOnMainThread:@selector(beginRefreshing) withObject:nil waitUntilDone:NO];
  
  contacts = [[ContactsManager sharedInstance] getContactsRefreshedNecessary:YES favourites:self.favoritesOnly];
  
  // UI must be on main thread
  [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
  [self.refreshControl performSelectorOnMainThread:@selector(endRefreshing) withObject:nil waitUntilDone:NO];
}

#pragma mark - Table View data source
- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
  // Return the number of rows in the section.
  return (section == 0) ? 2 : (contacts.count > 0) ? contacts.count : 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
  return 2;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  SWTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"userCell" forIndexPath:indexPath];
  
  // Clear default values
  [cell.textLabel setText:nil];
  [cell.detailTextLabel setText:nil];
  [cell.imageView setImage:nil];
  
  if (indexPath.section == 0) {
    [cell.textLabel setTextAlignment:NSTextAlignmentLeft];

    switch (indexPath.row) {
      case 0:
        [cell.textLabel setText:@"Twitter"];
        [cell.detailTextLabel setText:[[DUser currentUser] twitterUsername]];
        [cell.imageView setImage:[UIImage imageNamed:@"Twitter"]];
        break;
        
      case 1:
        [cell.textLabel setText:@"Facebook"];
        [cell.detailTextLabel setText:[[DUser currentUser] facebookUsername]];
        [cell.imageView setImage:[UIImage imageNamed:@"Facebook"]];
        break;
        
      default:
        break;
    }
    
  } else {
    if (!contacts || contacts.count == 0) {
      [cell.textLabel setText:@"Dude, you're alone... but not for long!"];
      
    } else {
      DUser *user = contacts[indexPath.row];
      
      ContactsManager *contactsManager = [ContactsManager sharedInstance];
      
      // Populate the cell
      cell.textLabel.text = user.username;
      cell.detailTextLabel.text = [contactsManager lastSeenForContactEmail:user.email];
      
      NSURL *profileImageURL = [NSURL URLWithString:user.profileImage.url];
      [cell.imageView sd_setImageWithURL:profileImageURL placeholderImage:[UIImage imageNamed:@"defaultProfileImage"]];
            
      // Buttons
      NSArray *utilityButtons = [self rightUtilityButtonsBlocked:[[DUser currentUser].blockedEmails containsObject:user.email] inFavorites:[[DUser currentUser].favouriteContactsEmails containsObject:user.email]];
      [cell setRightUtilityButtons:utilityButtons WithButtonWidth:[UIImage imageNamed:@"block"].size.width];
      
      cell.delegate = self;
      
    }
  }
  
  return cell;
}

- (NSArray*)rightUtilityButtonsBlocked:(BOOL)blocked inFavorites:(BOOL)favorited {
  UIImage *blockImage = [UIImage imageNamed:(blocked) ? @"unblock" : @"block"];
  UIImage *favoritesImage = [UIImage imageNamed:(favorited) ? @"removeFavorites" : @"addFavorites"];

  NSMutableArray *rightUtilityButtons = [NSMutableArray new];
  
  [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor clearColor] icon:[UIImage imageNamed:@"request"]];
  [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor clearColor] icon:blockImage];
  [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor clearColor] icon:favoritesImage];
  
  return [rightUtilityButtons copy];
}

- (void)swipeableTableViewCell:(SWTableViewCell*)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
  ContactsManager *contactsManager = [ContactsManager sharedInstance];

  DUser *user = contacts[[self.tableView indexPathForCell:cell].row];

  switch (index) {
    case 0: {
      [contactsManager requestStatusForContact:user inBackground:YES];
      break;
    }
      
    case 1: {
      BOOL blocked = [[DUser currentUser].blockedEmails containsObject:user.email];
      if (blocked) {
        [contactsManager unblockContact:user];
     
      } else {
        [contactsManager blockContact:user];
      }
      
      // Update buttons
      blocked = [[DUser currentUser].blockedEmails containsObject:user.email];
      
      NSArray *utilityButtons = [self rightUtilityButtonsBlocked:blocked inFavorites:[[DUser currentUser].favouriteContactsEmails containsObject:user.email]];
      [cell setRightUtilityButtons:utilityButtons WithButtonWidth:[UIImage imageNamed:@"request"].size.width];
      
      break;
    }
      
    case 2: {
      [contactsManager addContactToFavourites:user];
      
      break;
    }
      
    default: {
      break;
    }
  }
  
  [cell hideUtilityButtonsAnimated:YES];
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
  
  if (indexPath.section == 0) {
    switch (indexPath.row) {
      case 0:
        if ([cell.detailTextLabel.text isEqualToString:@"No Account Selected"]) {
          [[DUser currentUser] selectTwitterAccountWithCompletion:^(BOOL success, ACAccount *account, NSError *error) {
            if (success && account) {
              selectedTwitter = YES;
              
              dispatch_sync(dispatch_get_main_queue(), ^{
                [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
              });
              
            } else {
              [DUser showSocialServicesAlert];
              selectedTwitter = NO;
            }
          }];
          
        } else {
          if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
            selectedTwitter = NO;
            cell.accessoryType = UITableViewCellAccessoryNone;
            
          } else {
            selectedTwitter = YES;
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
          }
        }
        break;
        
      case 1:
        if ([cell.detailTextLabel.text isEqualToString:@"No Account Selected"]) {
          [[DUser currentUser] selectFacebookAccountWithCompletion:^(BOOL success, ACAccount *account, NSError *error) {
            if (success && account) {
              selectedFacebook = YES;
              
              dispatch_sync(dispatch_get_main_queue(), ^{
                [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
              });
            
            } else {
              [DUser showSocialServicesAlert];
              selectedFacebook = NO;
            }
          }];
          
        } else {
          if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
            selectedFacebook = NO;
            cell.accessoryType = UITableViewCellAccessoryNone;
            
          } else {
            selectedFacebook = YES;
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
          }
        }
        break;
        
      default:
        break;
    }
    
  } else if (indexPath.section == 1) {
    if (!contacts) {
      [self addContact];
      
    } else {
      if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
        [selectedContacts removeObject:contacts[indexPath.row]];
        cell.accessoryType = UITableViewCellAccessoryNone;
        
      } else {
        [selectedContacts addObject:contacts[indexPath.row]];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
      }
    }
  }
  
  self.navigationItem.rightBarButtonItem.enabled = (!selectedTwitter && !selectedFacebook && (selectedContacts.count == 0 || !selectedContacts)) ? NO : YES;
  
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Adding Contact
- (void)addContact {
  dispatch_async(dispatch_get_main_queue(), ^{
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Enter Contact Email" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [ac addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:NULL]];
    
    [ac addAction:[UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
      UITextField *textField = (UITextField*)ac.textFields[0];
      textField.hidden = YES;
      textField.enabled = NO;
      
      BOOL success = [[ContactsManager sharedInstance] addContactEmail:textField.text sendNotification:YES];
      
      if (!success) {
        UIAlertController *errorAC = [UIAlertController alertControllerWithTitle:@"Could not find contact" message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        [errorAC addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:NULL]];
        
        [self presentViewController:errorAC animated:YES completion:NULL];
      }
      
        [self performSelectorInBackground:@selector(reloadData) withObject:nil];
    }]];
    
    [ac addTextFieldWithConfigurationHandler:^(UITextField *textField) {
      textField.placeholder = @"friend@getdudeapp.com";
      [textField setKeyboardType:UIKeyboardTypeEmailAddress];
    }];
    
    [self presentViewController:ac animated:YES completion:NULL];
  });
}

#pragma mark - Showing Messages

- (void)showMessages {
  [self performSegueWithIdentifier:@"messagesSegue" sender:selectedContacts];
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
  [super prepareForSegue:segue sender:sender];
  
  if ([segue.identifier isEqualToString:@"messagesSegue"]) {
    MessagesTableViewController *messagesTableVC = (MessagesTableViewController*)segue.destinationViewController;
    messagesTableVC.selectedUsers = sender;
    messagesTableVC.selectedTwitter = selectedTwitter;
    messagesTableVC.selectedFacebook = selectedFacebook;
  }
}

#pragma mark - Status Bar
- (BOOL)prefersStatusBarHidden {return NO;}
- (UIStatusBarStyle)preferredStatusBarStyle {return UIStatusBarStyleDefault;}

@end