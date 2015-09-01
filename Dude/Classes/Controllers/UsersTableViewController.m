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
  
  UIImageView *leftBarButtonitemImageView;
  UIImageView *resultImageView;
  
  UILabel *resultNameLabel;
  
  UIButton *resultButton;
  
  UIView *textfieldView;
  
  UIVisualEffectView *friendSearchView;
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
  nextButton.tintColor = [UIColor whiteColor];

  [self.navigationItem setRightBarButtonItem:nextButton];
  
  // Add + to nav bar
  leftBarButtonitemImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Add Button"]];
  leftBarButtonitemImageView.autoresizingMask = UIViewAutoresizingNone;
  leftBarButtonitemImageView.contentMode = UIViewContentModeCenter;
  
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  button.frame = CGRectMake(0, 0, 40, 40);
  [button addSubview:leftBarButtonitemImageView];
  [button addTarget:self action:@selector(beginFriendSearch:) forControlEvents:UIControlEventTouchUpInside];
  
  leftBarButtonitemImageView.center = button.center;
  
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
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
      [cell.textLabel setText:@"Dude, you're alone... Tap the + to add friends"];
      
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
    if (contacts && contacts.count > 0) {
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
- (void)beginFriendSearch:(UIButton*)sender {
  // Modify the target of the button
  [sender removeTarget:self action:@selector(beginFriendSearch:) forControlEvents:UIControlEventAllEvents];
  [sender addTarget:self action:@selector(exitFriendSearch:) forControlEvents:UIControlEventTouchUpInside];

  // Results interface
  friendSearchView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
  friendSearchView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
  friendSearchView.alpha = 0.0;
  
  resultImageView  = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetMidX(friendSearchView.frame)-75, CGRectGetMidY(friendSearchView.frame)-75, 150, 150)];
  resultImageView.layer.cornerRadius = 75;
  resultImageView.clipsToBounds = YES;
  
  resultNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMidX(friendSearchView.frame)-75, resultImageView.frame.size.height+resultImageView.frame.origin.y+15, 150, 25)];
  resultNameLabel.textAlignment = NSTextAlignmentCenter;
  resultNameLabel.adjustsFontSizeToFitWidth = YES;

  resultButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMidX(friendSearchView.frame)-25, resultImageView.frame.size.height+resultNameLabel.frame.origin.y+7, 50, 25)];

  [friendSearchView addSubview:resultImageView];
  [friendSearchView addSubview:resultNameLabel];
  [friendSearchView addSubview:resultButton];

  // Create textfield for friend search
  textfieldView = [[UIView alloc] initWithFrame:CGRectMake(0, -44, self.view.frame.size.width, 64)];
  textfieldView.backgroundColor = self.navigationController.navigationBar.barTintColor;
  
  UITextField *searchTextfield = [[UITextField alloc] initWithFrame:CGRectMake(22, 24, self.view.frame.size.width-44, 30)];
  searchTextfield.alpha = 0.0;
  searchTextfield.backgroundColor = [UIColor whiteColor];
  searchTextfield.keyboardType = UIKeyboardTypeEmailAddress;
  searchTextfield.borderStyle = UITextBorderStyleRoundedRect;
  searchTextfield.placeholder = @"friend@getdudeapp.com";
  
  [searchTextfield addTarget:self action:@selector(textfieldValueChanged:) forControlEvents:UIControlEventEditingChanged];
  
  // Add all the subviews
  [self.view addSubview:friendSearchView];
  [textfieldView addSubview:searchTextfield];
  [self.view addSubview:textfieldView];

  // Animate in
  [UIView animateWithDuration:0.3 animations:^{
    leftBarButtonitemImageView.transform = CGAffineTransformMakeRotation(M_PI/4);
    friendSearchView.alpha = 1.0;
    searchTextfield.alpha = 0.8;
    
    textfieldView.center = CGPointMake(self.navigationController.navigationBar.center.x, self.navigationController.navigationBar.center.y-20);
    
  } completion:^(BOOL finished) {
    [searchTextfield becomeFirstResponder];
  }];
}

- (void)textfieldValueChanged:(UITextField*)textfield {
#warning to do fill in image names
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    if (![self validateEmail:textfield.text withAlert:NO]) {
      [resultButton setImage:[UIImage imageNamed:@"Enter Email"] forState:UIControlStateNormal];
      
      dispatch_async(dispatch_get_main_queue(), ^{
        if (![resultNameLabel.text isEqualToString:@""] || resultImageView.image != nil) {
          [UIView animateWithDuration:0.25 animations:^{
            [resultImageView setImage:nil];
            resultNameLabel.text = @"";
          }];
        }
      });
      
    } else {
      [resultButton setImage:[UIImage imageNamed:@"requested"] forState:UIControlStateNormal];

      // Get the user with that email to make sure its valid
      PFQuery *userQuery = [DUser query];
      [userQuery whereKey:@"email" equalTo:textfield.text.lowercaseString];
      
      DUser *user = (DUser*)[userQuery getFirstObject];
      
      // If valid update results UI
      if (user) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [UIView animateWithDuration:0.25 animations:^{
            [resultImageView sd_setImageWithURL:[NSURL URLWithString:user.profileImage.url] placeholderImage:[UIImage imageNamed:@"defaultProfileImage"] options:SDWebImageHighPriority];
            resultNameLabel.text = user.fullName;
          }];
        });
        
        NSString *imageName;
        if ([[ContactsManager sharedInstance] contactBlockedCurrentUser:user]) {
          imageName = @"";
        
        } else if ([[DUser currentUser].contactsEmails containsObject:user.email.lowercaseString]) {
          imageName = @"";
        
        } else {
          imageName = @"";
        }
        
        [resultButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
      
      } else {
        [resultButton setImage:[UIImage imageNamed:@"No user"] forState:UIControlStateNormal];
      }
    }
  });
}

- (void)exitFriendSearch:(UIButton*)sender {
  // Modify the target of the button
  [sender removeTarget:self action:@selector(exitFriendSearch:) forControlEvents:UIControlEventAllEvents];
  [sender addTarget:self action:@selector(beginFriendSearch:) forControlEvents:UIControlEventTouchUpInside];
  
  // Animate in
  [UIView animateWithDuration:0.3 animations:^{
    leftBarButtonitemImageView.transform = CGAffineTransformMakeRotation(0);
    friendSearchView.alpha = 0.0;
    textfieldView.center = CGPointMake(self.navigationController.navigationBar.center.x, -self.navigationController.navigationBar.center.y);
    
  } completion:^(BOOL finished) {
    [resultImageView removeFromSuperview];
    resultImageView = nil;
    
    [resultNameLabel removeFromSuperview];
    resultNameLabel = nil;
    
    [resultButton removeFromSuperview];
    resultButton = nil;
    
    [friendSearchView removeFromSuperview];
    friendSearchView = nil;

    [textfieldView removeFromSuperview];
    textfieldView = nil;
  }];
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

#pragma mark - Email Validation
- (BOOL)validateEmail:(NSString*)email withAlert:(BOOL)showAlert {
  BOOL validEmail = [self validateEmailFormat:email];
  
  if (!validEmail && showAlert) {
    NSString *title = @"Email Invalid";
    NSString *message = @"This email appears to be invalid, please check for typos.";
    
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [ac addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:ac animated:YES completion:nil];
    
    return NO;
  }
  
  return validEmail;
}

- (BOOL)validateEmailFormat:(NSString*)candidate {
  NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}";
  NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];

  return [emailTest evaluateWithObject:candidate];
}

#pragma mark - Status Bar
- (BOOL)prefersStatusBarHidden {return NO;}
- (UIStatusBarStyle)preferredStatusBarStyle {return UIStatusBarStyleDefault;}

@end