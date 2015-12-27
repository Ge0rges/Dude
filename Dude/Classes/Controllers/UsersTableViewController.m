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
#import "SlidingSegues.h"

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

@interface UsersTableViewController () <UITableViewDataSource, UITableViewDelegate> {
  NSArray *activeContacts;
  NSArray *favoriteContacts;
  NSArray *allContacts;

  UIImageView *leftBarButtonitemImageView;
  
  DUser *friendSearchedUser;
  
  UIButton *addButton;
}

@property (nonatomic) BOOL favoritesOnly;

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;

@property (strong, nonatomic) IBOutlet UIView *nofavoritesView;
@property (strong, nonatomic) IBOutlet UIView *noFriendsView;

// Friends Search View
@property (strong, nonatomic) IBOutlet UIView *searchTextfieldView;

@property (strong, nonatomic) IBOutlet UITextField *searchTextfield;

@property (strong, nonatomic) IBOutlet UIButton *searchResultButton;

@property (strong, nonatomic) IBOutlet UIVisualEffectView *searchFriendsView;

@property (strong, nonatomic) IBOutlet UIImageView *searchResultImageView;

@property (strong, nonatomic) IBOutlet UILabel *searchResultLabel;

@end

@implementation UsersTableViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  // Set controller properties
  self.favoritesOnly = NO;
  
  // Load initial data
  [self performSelectorInBackground:@selector(reloadData:) withObject:nil];
  
  // Update status bar
  [self setNeedsStatusBarAppearanceUpdate];
  
  // Set a timer to update the users every 5 minutes
  [NSTimer timerWithTimeInterval:300 target:self selector:@selector(reloadData:) userInfo:nil repeats:YES];
  
  // Add device contacts
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    [[ContactsManager sharedInstance] addDeviceContactsAndSendNotification:YES];
  });
  
  // Add + to nav bar
  leftBarButtonitemImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Add Button"]];
  leftBarButtonitemImageView.autoresizingMask = UIViewAutoresizingNone;
  leftBarButtonitemImageView.contentMode = UIViewContentModeCenter;
  
  addButton = [UIButton buttonWithType:UIButtonTypeCustom];
  addButton.frame = CGRectMake(0, 0, 40, 40);
  [addButton addSubview:leftBarButtonitemImageView];
  [addButton addTarget:self action:@selector(beginFriendSearch:) forControlEvents:UIControlEventTouchUpInside];
  
  leftBarButtonitemImageView.center = addButton.center;
  
  NSMutableArray *items  = [NSMutableArray arrayWithArray:self.toolbar.items];
  [items insertObject:[[UIBarButtonItem alloc] initWithCustomView:addButton] atIndex:0];
  
  [self.toolbar setItems:items];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  // Tell the delegate we are the visible view
  AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
  appDelegate.visibleViewController = self;
  
  BOOL shouldRefreshTwitter = [[NSUserDefaults standardUserDefaults] boolForKey:@"askTwitter"];
  BOOL shouldRefreshFacebook = [[NSUserDefaults standardUserDefaults] boolForKey:@"askFacebook"];
  
  if (shouldRefreshTwitter) {
    [[DUser currentUser] selectTwitterAccountWithCompletion:^(BOOL success, ACAccount *account, NSError *error) {
      if (shouldRefreshFacebook) {
        [[DUser currentUser] selectFacebookAccountWithCompletion:^(BOOL success, ACAccount *account, NSError *error) {
          [self performSelectorInBackground:@selector(reloadData:) withObject:nil];
        }];
        
      } else {
        [self performSelectorInBackground:@selector(reloadData:) withObject:nil];
      }
    }];
    
  } else if (shouldRefreshFacebook) {
    [[DUser currentUser] selectFacebookAccountWithCompletion:^(BOOL success, ACAccount *account, NSError *error) {
      [self performSelectorInBackground:@selector(reloadData:) withObject:nil];
    }];
  }
}

#pragma mark - Public Methods
- (IBAction)reloadData:(UISegmentedControl*)segmentedController {
  if (segmentedController) {
    self.favoritesOnly = segmentedController.selectedSegmentIndex;
  }
  
  ContactsManager *contactsManager = [ContactsManager sharedInstance];
  if (segmentedController) {
    activeContacts = (self.favoritesOnly) ? favoriteContacts : allContacts;
  
  } else {
    if (self.favoritesOnly) {
      favoriteContacts = [contactsManager getContactsRefreshedNecessary:YES favourites:YES];
      activeContacts = favoriteContacts;
    
    } else {
      allContacts = [contactsManager getContactsRefreshedNecessary:YES favourites:NO];
      activeContacts = allContacts;

    }
  }
  
  if (activeContacts.count == 0) {
    if (self.favoritesOnly) {
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
      
    } else {
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
    }

  } else {
    // Hide all
    
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
  
  // UI must be on main thread
  [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
}

#pragma mark - Table View data source
- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
  // Return the number of rows in the section.
  return activeContacts.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
  return 1;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
  return (self.favoritesOnly) ? @"ALL FAVORITES" : @"ALL FRIENDS";
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"userCell" forIndexPath:indexPath];
  
  // Clear default values
  [cell.textLabel setText:nil];
  [cell.detailTextLabel setText:nil];
  [cell.imageView setImage:nil];
  
  DUser *user = activeContacts[indexPath.row];
  
  // Populate the cell
  cell.textLabel.text = user.fullName;
  cell.detailTextLabel.text = [[ContactsManager sharedInstance] lastMessageForContact:user].lastSeen;
  [cell.imageView sd_setImageWithURL:[NSURL URLWithString:user.profileImage.url] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
    [UIView animateWithDuration:0.15 animations:^{
      [cell.imageView setImage:[image resizedImage:CGSizeMake(50, 50) interpolationQuality:kCGInterpolationHigh]];
      [cell layoutSubviews];
    }];
  }];
  
  return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  if (activeContacts && activeContacts.count > 0) {
    [self performSegueWithIdentifier:@"showProfile" sender:activeContacts[indexPath.row]];
  }
  
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
  if ([cell respondsToSelector:@selector(tintColor)]) {
      CGFloat cornerRadius = 7.f;
      cell.backgroundColor = UIColor.clearColor;
      CAShapeLayer *layer = [[CAShapeLayer alloc] init];
      CGMutablePathRef pathRef = CGPathCreateMutable();
      CGRect bounds = CGRectInset(cell.bounds, 10, 0);
      BOOL addLine = NO;
      
      if (indexPath.row == 0 && indexPath.row == [tableView numberOfRowsInSection:indexPath.section]-1) {
        CGPathAddRoundedRect(pathRef, nil, bounds, cornerRadius, cornerRadius);
      
      } else if (indexPath.row == 0) {
        CGPathMoveToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMaxY(bounds));
        CGPathAddArcToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMinY(bounds), CGRectGetMidX(bounds), CGRectGetMinY(bounds), cornerRadius);
        CGPathAddArcToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMinY(bounds), CGRectGetMaxX(bounds), CGRectGetMidY(bounds), cornerRadius);
        CGPathAddLineToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMaxY(bounds));
        addLine = YES;
      
      } else if (indexPath.row == [tableView numberOfRowsInSection:indexPath.section]-1) {
        CGPathMoveToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMinY(bounds));
        CGPathAddArcToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMaxY(bounds), CGRectGetMidX(bounds), CGRectGetMaxY(bounds), cornerRadius);
        CGPathAddArcToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMaxY(bounds), CGRectGetMaxX(bounds), CGRectGetMidY(bounds), cornerRadius);
        CGPathAddLineToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMinY(bounds));
      
      } else {
        CGPathAddRect(pathRef, nil, bounds);
        addLine = YES;
      }
      
      layer.path = pathRef;
      CFRelease(pathRef);
      layer.fillColor = [UIColor colorWithWhite:1.f alpha:0.8f].CGColor;
      
      if (addLine == YES) {
        CALayer *lineLayer = [[CALayer alloc] init];
        CGFloat lineHeight = (1.f / [UIScreen mainScreen].scale);
        lineLayer.frame = CGRectMake(CGRectGetMinX(bounds)+10, bounds.size.height-lineHeight, bounds.size.width-10, lineHeight);
        lineLayer.backgroundColor = tableView.separatorColor.CGColor;
        [layer addSublayer:lineLayer];
      }
      
      UIView *testView = [[UIView alloc] initWithFrame:bounds];
      [testView.layer insertSublayer:layer atIndex:0];
      testView.backgroundColor = UIColor.clearColor;
      cell.backgroundView = testView;
  }
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
  if ([segue.identifier isEqualToString:@"showProfile"]) {
    ProfileViewController *pvc = (ProfileViewController*)[segue destinationViewController];
    pvc.profileUser = sender;
  }
}

#pragma mark - Adding Contact
- (void)beginFriendSearch:(UIButton*)sender {
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

  // Animate in
  self.searchFriendsView.alpha = 0.0;
  self.searchFriendsView.hidden = NO;
  self.searchTextfieldView.center = CGPointMake(self.toolbar.center.x, -self.toolbar.center.y);
  
  [self.view bringSubviewToFront:self.searchFriendsView];
  
  [UIView animateWithDuration:0.3 animations:^{
    leftBarButtonitemImageView.transform = CGAffineTransformMakeRotation(M_PI/4);
    self.searchFriendsView.alpha = 1.0;
    self.searchTextfieldView.center = CGPointMake(self.toolbar.center.x, self.toolbar.center.y);
    
  } completion:^(BOOL finished) {
    [self.searchTextfield becomeFirstResponder];
  }];

  // Modify the target of the button
  [addButton removeTarget:self action:@selector(beginFriendSearch:) forControlEvents:UIControlEventAllEvents];
  [addButton addTarget:self action:@selector(exitFriendSearch:) forControlEvents:UIControlEventTouchUpInside];
}

- (IBAction)textfieldValueChanged:(UITextField*)textfield {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    [self.searchResultButton removeTarget:self action:@selector(addFriend) forControlEvents:UIControlEventTouchUpInside];
    
    if (![self validateEmail:textfield.text withAlert:NO]) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [self.searchResultButton setImage:nil forState:UIControlStateNormal];
        [self.searchResultButton setTitle:@"" forState:UIControlStateNormal];
        [self.searchResultLabel setText:@"Dude enter your friend's email"];
        
        if (![self.searchResultLabel.text isEqualToString:@""] || self.searchResultImageView.image != nil) {
          [UIView animateWithDuration:0.3 animations:^{
            [self.searchResultImageView setImage:nil];
            self.searchResultLabel.text = @"";
          }];
        }
      });
      
    } else {
      dispatch_async(dispatch_get_main_queue(), ^{
        [self.searchResultLabel setText:@"Searching..."];
        [self.searchResultButton setTitle:@"" forState:UIControlStateNormal];
      });
      
      // Get the user with that email to make sure its valid
      PFQuery *userQuery = [DUser query];
      [userQuery whereKey:@"email" equalTo:textfield.text.lowercaseString];
      
      friendSearchedUser = (DUser*)[userQuery getFirstObject];
      
      // If valid update results UI
      dispatch_async(dispatch_get_main_queue(), ^{
        if (friendSearchedUser) {
          [UIView animateWithDuration:0.3 animations:^{
            [self.searchResultImageView sd_setImageWithURL:[NSURL URLWithString:friendSearchedUser.profileImage.url] placeholderImage:[UIImage imageNamed:@"Default Profile Image"] options:SDWebImageHighPriority];
            self.searchResultLabel.text = friendSearchedUser.fullName;
          }];
          
          NSString *imageName;
          if ([[ContactsManager sharedInstance] contactBlockedCurrentUser:friendSearchedUser]) {
            imageName = @"Blocked Friend Search";
            
          } else if ([[DUser currentUser].contactsEmails containsObject:friendSearchedUser.email.lowercaseString]) {
            imageName = @"Friends Friend Search";
            
          } else {
            imageName = @"Add Friend Search";
            [self.searchResultButton addTarget:self action:@selector(addFriend) forControlEvents:UIControlEventTouchUpInside];
          }
          
          [self.searchResultButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
          
        }  else {
          [self.searchResultLabel setText:@"Not Found."];
          [self.searchResultButton setImage:nil forState:UIControlStateNormal];
          [self.searchResultButton setTitle:@"Double check the email you entered." forState:UIControlStateNormal];
        }
        
        [self.searchResultButton sizeToFit];
      });
    }
  });
}

- (void)addFriend {
  [[ContactsManager sharedInstance] addContactToContacts:friendSearchedUser sendNotification:YES];
  [self exitFriendSearch:self.searchResultButton];
}

- (void)exitFriendSearch:(UIButton*)sender {
  // Animate out
  [UIView animateWithDuration:0.3 animations:^{
    leftBarButtonitemImageView.transform = CGAffineTransformMakeRotation(0);
    self.searchFriendsView.alpha = 0.0;
    self.searchTextfieldView.center = CGPointMake(self.toolbar.center.x, -self.toolbar.center.y);
    
  } completion:^(BOOL finished) {
    self.searchFriendsView.hidden = YES;
    [self.view sendSubviewToBack:self.searchFriendsView];
  }];
  
  [self performSelectorOnMainThread:@selector(reloadData:) withObject:nil waitUntilDone:NO];
  
  // Modify the target of the button
  [addButton removeTarget:self action:@selector(exitFriendSearch:) forControlEvents:UIControlEventAllEvents];
  [addButton addTarget:self action:@selector(beginFriendSearch:) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - Navigation
- (IBAction)unwindToUsersTableViewController:(UIStoryboardSegue*)segue {}


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
- (UIStatusBarStyle)preferredStatusBarStyle {return UIStatusBarStyleLightContent;}

@end