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

// Managers
#import "ContactsManager.h"
#import "MessagesManager.h"

// Controllers
#import "MessagesTableViewController.h"
#import "ProfileViewController.h"

// Extensions & Categories
#import "UIImageExtensions.h"

// Constants
#import "Constants.h"

typedef void(^completion)(BOOL validEmail);

@interface UsersTableViewController () <UITableViewDataSource, UITableViewDelegate> {
  NSSet *allContacts;
  NSSet *favoriteContacts;
  
  UIImageView *leftBarButtonitemImageView;
  
  DUser *friendSearchedUser;
  
  UIButton *addButton;
  
  NSBlockOperation *fetchUsersOperation;
}

@property (nonatomic) BOOL favoritesOnly;

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) IBOutlet UIView *nofavoritesView;
@property (strong, nonatomic) IBOutlet UIView *noFriendsView;

@property (strong, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

// Friends Search View
@property (strong, nonatomic) IBOutlet UIView *searchTextfieldView;

@property (strong, nonatomic) IBOutlet UITextField *searchTextfield;

@property (strong, nonatomic) IBOutlet UIButton *searchResultButton;

@property (strong, nonatomic) IBOutlet UIVisualEffectView *searchFriendsView;

@property (strong, nonatomic) IBOutlet UIImageView *searchResultImageView;

@property (strong, nonatomic) IBOutlet UILabel *searchResultLabel;

@property (strong, nonatomic) UIRefreshControl *refreshControl;

@end

@implementation UsersTableViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  // Set controller properties
  self.favoritesOnly = NO;
  
  // Update status bar
  [self setNeedsStatusBarAppearanceUpdate];
  
  // Set a timer to update the users every 5 minutes
  [self reloadData:nil];
  [NSTimer timerWithTimeInterval:300 target:self selector:@selector(reloadData:) userInfo:nil repeats:YES];
  
  // Add device contacts
  [[ContactsManager sharedInstance] addDeviceContactsAndSendNotification:YES];
  
  // Add + to nav bar
  leftBarButtonitemImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Add Button"]];
  leftBarButtonitemImageView.autoresizingMask = UIViewAutoresizingNone;
  leftBarButtonitemImageView.contentMode = UIViewContentModeCenter;
  
  addButton = [UIButton buttonWithType:UIButtonTypeCustom];
  addButton.frame = CGRectMake(0, 0, 40, 40);
  [addButton addSubview:leftBarButtonitemImageView];
  [addButton addTarget:self action:@selector(beginFriendSearch:) forControlEvents:UIControlEventTouchUpInside];
  
  leftBarButtonitemImageView.center = addButton.center;
  
  [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:addButton]];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  // Tell the delegate we are the visible view
  AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
  appDelegate.visibleViewController = self;
  
  BOOL shouldRefreshTwitter = [NSUserDefaults.standardUserDefaults boolForKey:@"askTwitter"];
  BOOL shouldRefreshFacebook = [NSUserDefaults.standardUserDefaults boolForKey:@"askFacebook"];
  
  if (shouldRefreshTwitter) {
    [DUser selectTwitterAccountWithCompletion:nil];
  }
  
  if (shouldRefreshFacebook) {
    [DUser selectFacebookAccountWithCompletion:nil];
  }
  
  // Add refresh control
  UITableViewController *tableViewController = [[UITableViewController alloc] init];
  tableViewController.tableView = self.tableView;
  
  self.refreshControl = [[UIRefreshControl alloc] init];
  [self.refreshControl addTarget:self action:@selector(reloadData:) forControlEvents:UIControlEventValueChanged];
  self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Contacting other dudes..."];
  self.refreshControl.tintColor = self.view.tintColor;
  
  tableViewController.refreshControl = self.refreshControl;
  
  // Renew accounts
  ACAccountStore *accountStore = [ACAccountStore new];
  ACAccount *twitterAccount = [accountStore accountWithIdentifier:[NSUserDefaults.standardUserDefaults stringForKey:@"twiterAccountID"]];
  ACAccount *facebookAccount = [accountStore accountWithIdentifier:[NSUserDefaults.standardUserDefaults stringForKey:@"facebookAccountID"]];
  
  if (twitterAccount) {
    [accountStore renewCredentialsForAccount:twitterAccount completion:^(ACAccountCredentialRenewResult renewResult, NSError *error) {
      
      if (renewResult == ACAccountCredentialRenewResultRejected) {
        [NSUserDefaults.standardUserDefaults setObject:@"" forKey:@"twiterAccountID"];
      }
      
      [accountStore renewCredentialsForAccount:facebookAccount completion:^(ACAccountCredentialRenewResult renewResult, NSError *error) {
        if (renewResult == ACAccountCredentialRenewResultRejected) {
          [NSUserDefaults.standardUserDefaults setObject:@"" forKey:@"facebookAccountID"];
        }
      }];
    }];
    
  } else if (facebookAccount) {
    [accountStore renewCredentialsForAccount:facebookAccount completion:^(ACAccountCredentialRenewResult renewResult, NSError *error) {
      if (renewResult == ACAccountCredentialRenewResultRejected) {
        [NSUserDefaults.standardUserDefaults setObject:@"" forKey:@"facebookAccountID"];
      }
    }];
  }
  
  // CloudKit discoverability
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [[CKContainer defaultContainer] requestApplicationPermission:CKApplicationPermissionUserDiscoverability completionHandler:^(CKApplicationPermissionStatus applicationPermissionStatus, NSError * _Nullable error) {
      // Warn the user of the consequences.
      if (error) {
        UIAlertController *warningAlert = [UIAlertController alertControllerWithTitle:@"Dudes can't find you!" message:@"Dude, other dudes won't be able to send you brofists by disabling discovery. Your personal information is secure and private always, relaunch the app to enable." preferredStyle:UIAlertControllerStyleAlert];
        [warningAlert addAction:[UIAlertAction actionWithTitle:@"Yep, dudes can't find me." style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
          [warningAlert dismissViewControllerAnimated:YES completion:nil];
        }]];
        
        [self presentViewController:warningAlert animated:YES completion:nil];
      }
    }];
    
  });
}


#pragma mark - Public Methods
- (IBAction)reloadData:(id)sender {
  if (self.searchFriendsView.hidden) {
    // Determine if favorites
    if ([sender isEqual:self.segmentedControl]) {
      self.favoritesOnly = self.segmentedControl.selectedSegmentIndex;
    }
    
    // Update Table with new data in the background
    if ([fetchUsersOperation isExecuting]) return;// No double fetching
    
    fetchUsersOperation = [NSBlockOperation blockOperationWithBlock:^{
      if (!fetchUsersOperation.isCancelled) {
        BOOL fromCache = (![sender isEqual:self.segmentedControl] || ![sender isKindOfClass:[NSTimer class]]);
        
        [[ContactsManager sharedInstance] fetchContactsFromCache:fromCache favorites:self.favoritesOnly successBlock:^(NSArray<CKRecord *> * _Nullable fetchedUsers) {
          if (self.favoritesOnly) {
            favoriteContacts = [NSSet setWithArray:fetchedUsers];
          } else {
            allContacts = [NSSet setWithArray:fetchedUsers];
          }
          
          [self performSelectorOnMainThread:@selector(updateInterface) withObject:nil waitUntilDone:YES];
          
        } failureBlock:^(NSError * _Nullable error) {
          [self performSelectorOnMainThread:@selector(updateInterface) withObject:nil waitUntilDone:YES];

        }];
      }
      
      [self.refreshControl performSelectorOnMainThread:@selector(endRefreshing) withObject:nil waitUntilDone:NO];
    }];
    
    fetchUsersOperation.queuePriority = NSOperationQueuePriorityHigh;
    fetchUsersOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    
    [[[NSThread alloc] initWithTarget:fetchUsersOperation selector:@selector(start) object:nil] start];
  }
}

- (void)updateInterface {
  if (self.searchFriendsView.hidden) {
    // Update UI again on main thread
    [self.tableView reloadData];
    
    if (self.favoritesOnly && favoriteContacts.count == 0) {
      // Show no favorites
      [self.view bringSubviewToFront:self.nofavoritesView];
      
      self.nofavoritesView.alpha = 0.0;
      self.nofavoritesView.hidden = NO;
      
      [UIView animateWithDuration:0.3 animations:^{
        self.nofavoritesView.alpha = 1.0;
      }];
      
      // Hide no friends
      [UIView animateWithDuration:0.3 animations:^{
        self.noFriendsView.alpha = 0.0;
        
      } completion:^(BOOL finished) {
        self.noFriendsView.hidden = YES;
        [self.view sendSubviewToBack:self.noFriendsView];
      }];
      
    } else if (allContacts.count == 0) {
      // Show no friends
      [self.view bringSubviewToFront:self.noFriendsView];
      
      self.noFriendsView.alpha = 0.0;
      self.noFriendsView.hidden = NO;
      
      [UIView animateWithDuration:0.3 animations:^{
        self.noFriendsView.alpha = 1.0;
      }];
      
      // Hide no favorites
      [UIView animateWithDuration:0.3 animations:^{
        self.nofavoritesView.alpha = 0.0;
        
      } completion:^(BOOL finished) {
        self.nofavoritesView.hidden = YES;
        [self.view sendSubviewToBack:self.nofavoritesView];
      }];
      
      
    } else {
      // Hide all:
      // Hide no favorites
      [UIView animateWithDuration:0.3 animations:^{
        self.nofavoritesView.alpha = 0.0;
        
      } completion:^(BOOL finished) {
        self.nofavoritesView.hidden = YES;
        [self.view sendSubviewToBack:self.nofavoritesView];
      }];
      
      // Hide no friends
      [UIView animateWithDuration:0.3 animations:^{
        self.noFriendsView.alpha = 0.0;
        
      } completion:^(BOOL finished) {
        self.noFriendsView.hidden = YES;
        [self.view sendSubviewToBack:self.noFriendsView];
      }];
    }
  }
}


#pragma mark - Table View data source
- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
  // Return the number of rows in the section.
  return (self.favoritesOnly) ? favoriteContacts.count : allContacts.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
  return 1;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"userCell" forIndexPath:indexPath];
  
  // Clear default values
  [cell.textLabel setText:nil];
  [cell.detailTextLabel setText:nil];
  [cell.imageView setImage:[UIImage imageNamed:@"Default Profile Image"]];
  
  DUser *user = (self.favoritesOnly) ? [favoriteContacts allObjects][indexPath.row] : [allContacts allObjects][indexPath.row];
  
  // Populate the cell
  cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", user.firstName, user.lastName];
  cell.detailTextLabel.text = @"Asking what's up...";
  
  // This can take time do it on another thread
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    DMessage *message = [[ContactsManager sharedInstance] latestMessageForContact:user];
    
    dispatch_async(dispatch_get_main_queue(), ^{
      cell.detailTextLabel.text = (message) ? [NSString stringWithFormat:@"%@ - %@", message.lastSeen, message.timestamp] : @"Dude, no status available";
    });
  });
  
  [cell.imageView setImage:[[UIImage imageWithData:user.profileImageData] resizedImage:CGSizeMake(60, 60) interpolationQuality:kCGInterpolationHigh]];
  
  return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
  // Set transparent background so we can see the layer
  cell.backgroundColor = UIColor.clearColor;
  
  // Declare two layers: one for the background and one for the selecetdBackground
  CAShapeLayer *backgroundLayer = [CAShapeLayer layer];
  CAShapeLayer *selectedBackgroundLayer = [[CAShapeLayer alloc] init];
  
  CGRect bounds = CGRectInset(cell.bounds, 0, 0);//Cell bounds feel free to adjust insets.
  
  BOOL addSeparator = NO;// Controls if we should add a seperator
  
  // Determine which corners should be rounded
  if (indexPath.row == 0 && indexPath.row == [tableView numberOfRowsInSection:indexPath.section]-1) {
    // This is the only row in its section, round all corners
    backgroundLayer.path = [UIBezierPath bezierPathWithRoundedRect:bounds byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(7, 7)].CGPath;
    
  } else if (indexPath.row == 0) {
    // First row, round the top two corners.
    backgroundLayer.path = [UIBezierPath bezierPathWithRoundedRect:bounds byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(7, 7)].CGPath;
    addSeparator = YES;
    
  } else if (indexPath.row == [tableView numberOfRowsInSection:indexPath.section]-1) {
    // Bottom row, round the bottom two corners.
    backgroundLayer.path = [UIBezierPath bezierPathWithRoundedRect:bounds byRoundingCorners:UIRectCornerBottomLeft | UIRectCornerBottomRight cornerRadii:CGSizeMake(7, 7)].CGPath;
    
  } else {
    // Somewhere between the first and last row don't round anything but add a seperator
    backgroundLayer.path = [UIBezierPath bezierPathWithRect:bounds].CGPath;// So we have a background
    addSeparator = YES;
  }
  
  // Copy the same path for the selected background layer
  selectedBackgroundLayer.path = CGPathCreateCopy(backgroundLayer.path);
  
  // Yay colors!
  backgroundLayer.fillColor = [UIColor colorWithWhite:1.f alpha:0.8f].CGColor;
  selectedBackgroundLayer.fillColor = [UIColor grayColor].CGColor;
  
  // Draw seperator if necessary
  if (addSeparator == YES) {
    CALayer *separatorLayer = [CALayer layer];
    CGFloat separatorHeight = (1.f / [UIScreen mainScreen].scale);
    
    separatorLayer.frame = CGRectMake(CGRectGetMinX(bounds)+50, bounds.size.height-separatorHeight, bounds.size.width-70, separatorHeight);
    
    separatorLayer.backgroundColor = tableView.separatorColor.CGColor;
    
    [backgroundLayer addSublayer:separatorLayer];
  }
  
  
  // Create a UIView from these layers and set them to the cell's .backgroundView and .selectedBackgroundView
  UIView *backgroundView = [[UIView alloc] initWithFrame:bounds];
  [backgroundView.layer insertSublayer:backgroundLayer atIndex:0];
  backgroundView.backgroundColor = UIColor.clearColor;
  cell.backgroundView = backgroundView;
  
  UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:bounds];
  [selectedBackgroundView.layer insertSublayer:selectedBackgroundLayer atIndex:0];
  selectedBackgroundView.backgroundColor = UIColor.clearColor;
  cell.selectedBackgroundView = selectedBackgroundView;
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
  if ([segue.identifier isEqualToString:@"showProfile"]) {
    UITableViewCell *cell = (UITableViewCell*)sender;
    DUser *selectedUser = (self.favoritesOnly) ? [favoriteContacts allObjects][[self.tableView indexPathForCell:cell].row] : [allContacts allObjects][[self.tableView indexPathForCell:cell].row];
    
    ProfileViewController *pvc = (ProfileViewController*)[segue destinationViewController];
    pvc.profileUser = selectedUser;
  }
}

#pragma mark - Adding Contact
- (void)beginFriendSearch:(UIButton*)sender {
  // We do this know to be able to use .hidden as checks
  self.searchFriendsView.alpha = 0.0;
  self.searchFriendsView.hidden = NO;
  
  // Disable Segmented Control
  self.segmentedControl.enabled = NO;
  self.segmentedControl.userInteractionEnabled = NO;
  
  // Clear the UI
  if (!self.nofavoritesView.hidden) {
    [UIView animateWithDuration:0.3 animations:^{
      self.nofavoritesView.alpha = 0.0;
      
    } completion:^(BOOL finished) {
      self.nofavoritesView.hidden = YES;
      [self.view sendSubviewToBack:self.nofavoritesView];
    }];
  }
  
  if (!self.noFriendsView.hidden) {
    [UIView animateWithDuration:0.3 animations:^{
      self.noFriendsView.alpha = 0.0;
      
    } completion:^(BOOL finished) {
      self.noFriendsView.hidden = YES;
      [self.view sendSubviewToBack:self.noFriendsView];
    }];
  }
  
  // Reset the UI
  [self.searchResultButton setImage:nil forState:UIControlStateNormal];
  [self.searchResultButton setTitle:@"" forState:UIControlStateNormal];
  [self.searchResultLabel setText:@"Dude enter your friend's email"];
  [self.searchResultImageView setImage:[UIImage imageNamed:@"Default Profile Image"]];
  [self.searchTextfield setText:@""];
  
  
  // Animate in
  self.searchTextfieldView.center = CGPointMake(self.searchTextfieldView.frame.size.width/2, -self.searchTextfieldView.frame.size.height/2);
  
  [self.view bringSubviewToFront:self.searchFriendsView];
  
  [UIView animateWithDuration:0.3 animations:^{
    leftBarButtonitemImageView.transform = CGAffineTransformMakeRotation(M_PI/4);
    self.searchFriendsView.alpha = 1.0;
    self.searchTextfieldView.center = CGPointMake(self.searchTextfieldView.frame.size.width/2, self.searchTextfieldView.frame.size.height/2);
    
  } completion:^(BOOL finished) {
    [self.searchTextfield becomeFirstResponder];
  }];
  
  // Modify the target of the button
  [addButton removeTarget:self action:@selector(beginFriendSearch:) forControlEvents:UIControlEventAllEvents];
  [addButton addTarget:self action:@selector(exitFriendSearch:) forControlEvents:UIControlEventTouchUpInside];
  
  // Layout
  [self.searchFriendsView layoutSubviews];
}

- (IBAction)textfieldValueChanged:(UITextField*)textfield {
  
  [self.searchResultButton removeTarget:self action:@selector(addFriend) forControlEvents:UIControlEventTouchUpInside];
  
  if ([textfield.text isEqual:currentUser.recordID]) {
    [self.searchResultButton setImage:nil forState:UIControlStateNormal];
    [self.searchResultButton setTitle:@"You" forState:UIControlStateNormal];
    [self.searchResultLabel setText:@"Dude you can't add yourself :p"];
    [self.searchResultImageView setImage:[UIImage imageWithData:currentUser.profileImageData]];
    
    [self.searchResultButton sizeToFit];
    
    return;
  }
  
  [self validateEmail:textfield.text withAlert:NO completion:^(BOOL validEmail) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (!validEmail) {
        // Reset the UI
        [self.searchResultButton setImage:nil forState:UIControlStateNormal];
        [self.searchResultButton setTitle:@"" forState:UIControlStateNormal];
        [self.searchResultLabel setText:@"Dude enter your friend's email"];
        [self.searchResultImageView setImage:[UIImage imageNamed:@"Default Profile Image"]];
        
      } else {
        [self.searchResultLabel setText:@"Searching..."];
        [self.searchResultButton setTitle:@"" forState:UIControlStateNormal];
        
        // Get the user with that email to make sure its valid
        CKQuery *userQuery = [[CKQuery alloc] initWithRecordType:@"Users" predicate:[NSPredicate predicateWithFormat:@"creatorRecordId = %@" argumentArray:@[textfield.text]]];
        
        
        [[[CKContainer defaultContainer] publicCloudDatabase] performQuery:userQuery inZoneWithID:nil completionHandler:^(NSArray<CKRecord *> * _Nullable results, NSError * _Nullable error) {
          
          friendSearchedUser = (DUser*)[results firstObject];
          
          // If valid update results UI
          if (friendSearchedUser && !error) {
            NSString *imageName;
            if ([[ContactsManager sharedInstance] contactBlockedCurrentUser:friendSearchedUser]) {
              imageName = @"Blocked Friend Search";
              
            } else if ([currentUser.contacts containsObject:friendSearchedUser.recordID]) {
              imageName = @"Friends Friend Search";
              
            } else {
              imageName = @"Add Friend Search";
              [self.searchResultButton addTarget:self action:@selector(addFriend) forControlEvents:UIControlEventTouchUpInside];
            }
            
            [UIView animateWithDuration:0.3 animations:^{
              [self.searchResultImageView setImage:[UIImage imageWithData:friendSearchedUser.profileImageData]];
              self.searchResultLabel.text = [NSString stringWithFormat:@"%@ %@", friendSearchedUser.firstName, friendSearchedUser.lastName];
              [self.searchResultButton setTitle:nil forState:UIControlStateNormal];
              [self.searchResultButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
              
            }];
            
          }  else {
            friendSearchedUser = nil;
            
            [self.searchResultLabel setText:@"Not Found."];
            [self.searchResultButton setImage:nil forState:UIControlStateNormal];
            [self.searchResultButton setTitle:@"Double check the email you entered." forState:UIControlStateNormal];
            [self.searchResultImageView setImage:[UIImage imageNamed:@"Default Profile Image"]];
            
          }
          
          [self.searchResultButton sizeToFit];
        }];
      }
    });
  }];
}


- (void)addFriend {
  [[ContactsManager sharedInstance] addContactToContacts:friendSearchedUser sendNotification:YES];
  [self exitFriendSearch:self.searchResultButton];
  [self performSelectorOnMainThread:@selector(reloadData:) withObject:nil waitUntilDone:NO];
}

- (void)exitFriendSearch:(UIButton*)sender {
  // Animate out
  [UIView animateWithDuration:0.3 animations:^{
    leftBarButtonitemImageView.transform = CGAffineTransformMakeRotation(0);
    self.searchFriendsView.alpha = 0.0;
    [self.searchTextfield resignFirstResponder];
    self.searchTextfieldView.center = CGPointMake(self.searchTextfieldView.frame.size.width/2, -self.searchTextfieldView.frame.size.height/2);
    
  } completion:^(BOOL finished) {
    self.searchFriendsView.hidden = YES;
    [self.view sendSubviewToBack:self.searchFriendsView];
    
    // Show any views that were hidden
    [self performSelectorOnMainThread:@selector(updateInterface) withObject:nil waitUntilDone:NO];
  }];
  
  // Modify the target of the button
  [addButton removeTarget:self action:@selector(exitFriendSearch:) forControlEvents:UIControlEventAllEvents];
  [addButton addTarget:self action:@selector(beginFriendSearch:) forControlEvents:UIControlEventTouchUpInside];
  
  // Enable Segmented Control
  self.segmentedControl.enabled = YES;
  self.segmentedControl.userInteractionEnabled = YES;
}


#pragma mark - Email Validation
- (void)validateEmail:(NSString* _Nonnull)email withAlert:(BOOL)showAlert completion:(_Nonnull completion)completionBlock {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    BOOL validEmail = [self validateEmailFormat:email];
    
    if (!validEmail && showAlert) {
      NSString *title = @"Email Invalid";
      NSString *message = @"This email appears to be invalid, please check for typos.";
      
      UIAlertController *ac = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
      [ac addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
      
      [self presentViewController:ac animated:YES completion:nil];
      
      completionBlock(NO);
    }
    
    completionBlock(validEmail);
  });
}

- (BOOL)validateEmailFormat:(NSString*)candidate {
  NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}";
  NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
  
  return [emailTest evaluateWithObject:candidate];
}

#pragma mark - Status Bar
- (BOOL)prefersStatusBarHidden {return NO;}
- (UIStatusBarStyle)preferredStatusBarStyle {return UIStatusBarStyleLightContent;}

@end
