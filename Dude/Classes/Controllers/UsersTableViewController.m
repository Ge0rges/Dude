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
#import <SDWebImage/SDWebImageDownloader.h>

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
  
  DUser *currentUser = [DUser currentUser];

  // Tell the delegate we are the visible view
  AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
  appDelegate.visibleViewController = self;
  
  BOOL shouldRefreshTwitter = [[NSUserDefaults standardUserDefaults] boolForKey:@"askTwitter"];
  BOOL shouldRefreshFacebook = [[NSUserDefaults standardUserDefaults] boolForKey:@"askFacebook"];
  
  if (shouldRefreshTwitter) {
    [currentUser selectTwitterAccountWithCompletion:nil];
  }
  
  if (shouldRefreshFacebook) {
    [currentUser selectFacebookAccountWithCompletion:nil];
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
  ACAccount *twitterAccount = [accountStore accountWithIdentifier:[[NSUserDefaults standardUserDefaults] stringForKey:@"twiterAccountID"]];
  ACAccount *facebookAccount = [accountStore accountWithIdentifier:[[NSUserDefaults standardUserDefaults] stringForKey:@"facebookAccountID"]];

  if (twitterAccount) {
  [accountStore renewCredentialsForAccount:twitterAccount completion:^(ACAccountCredentialRenewResult renewResult, NSError *error) {
    
    if (renewResult == ACAccountCredentialRenewResultRejected) {
      [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"twiterAccountID"];
    }
    
    [accountStore renewCredentialsForAccount:facebookAccount completion:^(ACAccountCredentialRenewResult renewResult, NSError *error) {
      if (renewResult == ACAccountCredentialRenewResultRejected) {
        [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"facebookAccountID"];
      }
    }];
  }];
  
  } else if (facebookAccount) {
    [accountStore renewCredentialsForAccount:facebookAccount completion:^(ACAccountCredentialRenewResult renewResult, NSError *error) {
      if (renewResult == ACAccountCredentialRenewResultRejected) {
        [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"facebookAccountID"];
      }
    }];
  }
}

#pragma mark - Public Methods
- (IBAction)reloadData:(id)sender {
  if (self.searchFriendsView.hidden) {
    // Determine if favorites
    if ([sender isEqual:self.segmentedControl]) {
      self.favoritesOnly = self.segmentedControl.selectedSegmentIndex;
    }
    
    // Update Table with new data in the background
    [fetchUsersOperation cancel];// No double fetching
    
    fetchUsersOperation = [NSBlockOperation blockOperationWithBlock:^{
      if (!fetchUsersOperation.isCancelled) {
        if (self.favoritesOnly) {
          
          // If this is a user performed refresh or a system fetch
          if (![sender isEqual:self.segmentedControl] || !sender || [sender isKindOfClass:[NSTimer class]]) {
            // Get the latest favorites
            favoriteContacts = [[ContactsManager sharedInstance] getContactsRefreshedNecessary:YES favourites:self.favoritesOnly];
          
            // Update the UI
            [self performSelectorOnMainThread:@selector(updateInterface) withObject:nil waitUntilDone:NO];
          
          } else {
            // Get cached favs
            favoriteContacts = [[ContactsManager sharedInstance] getContactsRefreshedNecessary:NO favourites:self.favoritesOnly];
            
            // If there are no cached favs or this is a user performed refresh get the latest favs
            if (favoriteContacts.count == 0) {
              favoriteContacts = [[ContactsManager sharedInstance] getContactsRefreshedNecessary:YES favourites:self.favoritesOnly];
            }
            
            // Update the UI
            [self performSelectorOnMainThread:@selector(updateInterface) withObject:nil waitUntilDone:NO];

          }
        
        } else {
          // If this is a user performed refresh
          if (![sender isEqual:self.segmentedControl] || !sender || [sender isKindOfClass:[NSTimer class]]) {
            // Get the latest favorites
            allContacts = [[ContactsManager sharedInstance] getContactsRefreshedNecessary:YES favourites:self.favoritesOnly];
            
            // Update the UI
            [self performSelectorOnMainThread:@selector(updateInterface) withObject:nil waitUntilDone:NO];
            
          } else {
            // Get cached contacts
            allContacts = [[ContactsManager sharedInstance] getContactsRefreshedNecessary:NO favourites:self.favoritesOnly];
            
            // If there are no cached favs or this is a user performed refresh get the latest contacts
            if (allContacts.count == 0) {
              allContacts = [[ContactsManager sharedInstance] getContactsRefreshedNecessary:YES favourites:self.favoritesOnly];
            }
            
            // Update the UI
            [self performSelectorOnMainThread:@selector(updateInterface) withObject:nil waitUntilDone:NO];
            
          }
        }
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
  cell.textLabel.text = user.fullName;
  cell.detailTextLabel.text = @"Asking what's up...";

  // This can take time do it on another thread
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    DMessage *message = [[ContactsManager sharedInstance] latestMessageForContact:user];
    
    dispatch_async(dispatch_get_main_queue(), ^{
      cell.detailTextLabel.text = (message) ? [NSString stringWithFormat:@"%@ - %@", message.lastSeen, message.timestamp] : @"Dude didn't share an update yet";
    });
  });
  
  [cell.imageView sd_setImageWithURL:[NSURL URLWithString:user.profileImage.url] placeholderImage:[UIImage imageNamed:@"Default Profile Image"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
    [cell.imageView setImage:[image resizedImage:CGSizeMake(50, 50) interpolationQuality:kCGInterpolationHigh]];
    [cell layoutSubviews];
  }];
  
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
  DUser *currentUser = [DUser currentUser];

  [self.searchResultButton removeTarget:self action:@selector(addFriend) forControlEvents:UIControlEventTouchUpInside];

  if ([textfield.text isEqualToString:currentUser.email]) {
    [self.searchResultButton setImage:nil forState:UIControlStateNormal];
    [self.searchResultButton setTitle:@"You" forState:UIControlStateNormal];
    [self.searchResultLabel setText:@"Dude you can't add yourself :p"];
    [self.searchResultImageView sd_setImageWithURL:[NSURL URLWithString:currentUser.profileImage.url] placeholderImage:[UIImage imageNamed:@"Default Profile Image"]];
    
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
          
        } else if (![textfield.text isEqualToString:currentUser.email]) {
          [self.searchResultLabel setText:@"Searching..."];
          [self.searchResultButton setTitle:@"" forState:UIControlStateNormal];
          [self.searchResultImageView setImage:[UIImage imageNamed:@"Default Profile Image"]];

          
          // Get the user with that email to make sure its valid
          PFQuery *userQuery = [DUser query];
          [userQuery whereKey:@"email" equalTo:textfield.text.lowercaseString];
          
          [userQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            friendSearchedUser = (DUser*)object;
            
            // If valid update results UI
            if (friendSearchedUser && !error) {
              NSString *imageName;
              if ([[ContactsManager sharedInstance] contactBlockedCurrentUser:friendSearchedUser]) {
                imageName = @"Blocked Friend Search";
                
              } else if ([currentUser.contactsEmails containsObject:friendSearchedUser.email.lowercaseString]) {
                imageName = @"Friends Friend Search";
                
              } else {
                imageName = @"Add Friend Search";
                [self.searchResultButton addTarget:self action:@selector(addFriend) forControlEvents:UIControlEventTouchUpInside];
              }
              
              [UIView animateWithDuration:0.3 animations:^{
                [self.searchResultImageView sd_setImageWithURL:[NSURL URLWithString:friendSearchedUser.profileImage.url] placeholderImage:[UIImage imageNamed:@"Default Profile Image"] options:SDWebImageHighPriority];
                self.searchResultLabel.text = friendSearchedUser.fullName;
                [self.searchResultButton setTitle:nil forState:UIControlStateNormal];
                [self.searchResultButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];

              }];
              
            } else {
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
