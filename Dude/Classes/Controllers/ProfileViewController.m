//
//  ProfileViewController.m
//  Dude
//
//  Created by Georges Kanaan on 6/2/15.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

#import "ProfileViewController.h"

// Pods
#import <SDWebImage/UIImageView+WebCache.h>

// Frameworks
#import <MapKit/MapKit.h>

// Managers
#import "ContactsManager.h"

// Extensions & Categories
#import "UIImageExtensions.h"

// Classes
#import "AppDelegate.h"

// Controllers
#import "MessagesTableViewController.h"

@interface ProfileViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate> {
  CGRect originalProfileImageViewFrame;
  CGFloat heightConstant;
  
  MKPointAnnotation *userLocationAnnotation;
  
  NSTimer *updateTimestampTimer;
}

@property (strong, nonatomic) IBOutlet UIImageView *profileImageView;

@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *locationLabel;
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UILabel *sendUpdateLabel;

@property (strong, nonatomic) IBOutlet MKMapView *statusLocationMapView;

@property (strong, nonatomic) IBOutlet UIButton *favoriteButton;
@property (strong, nonatomic) IBOutlet UIButton *secondaryButton;
@property (strong, nonatomic) IBOutlet UIButton *requestStatusButton;

@property (strong, nonatomic) IBOutlet UIView *composeUpdateButton;

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;

@property (nonatomic) BOOL isCurrentUser;

@end

@implementation ProfileViewController
- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  
  // Update status bar
  [self setNeedsStatusBarAppearanceUpdate];
  
  // Check if we're showing the current user's profile
  if (!self.profileUser) {
    self.profileUser = [DUser currentUser];

    self.isCurrentUser = YES;
  }
  
  // Update UI
  [self updateProfileInterface];
  
#warning make this on notification
  // Refresh the timestamp and message
  [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(updateProfileInterface) userInfo:nil repeats:YES];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  if (self.isCurrentUser) {
    [self.profileUser fetchWithSuccessBlock:^(DUser * _Nullable fetchedUser) {
      self.profileUser = fetchedUser;
      
      // Update UI
      [self updateProfileInterface];

    } failureBlock:nil];
  }
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  // Tell the delegate we are the visible view
  AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
  appDelegate.visibleViewController = self;
  
  // ScrollView content size and insets
  [self updateScrollviewContentSizeAndInsets];
}

#pragma mark - UI
- (void)updateProfileInterface {
  // Do this asyncly
  DMessage *message = [[ContactsManager sharedInstance] latestMessageForContact:self.profileUser];

  // Status Update
  NSString *locationErrorText = (self.isCurrentUser) ? @"Dude, share a public location" : @"Dude, no known location";
  NSString *lastSeenErrorText = (self.isCurrentUser) ? @"Dude, share a public status" : @"Dude, no status available";
  
  NSString *locationText = [NSString stringWithFormat:@"%@ - %@", message.city, message.timestamp];
  
  self.locationLabel.text = (message.city && message.timestamp) ? locationText : locationErrorText;
  self.statusLabel.text = (message.lastSeen) ? message.lastSeen : lastSeenErrorText;
  
  // Refresh the timestamp and message
  if (message && !updateTimestampTimer) {
    updateTimestampTimer = [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(updateProfileInterface) userInfo:nil repeats:YES];
  }
  
  // Map
  BOOL sameCoordinate = (message.location.coordinate.latitude == userLocationAnnotation.coordinate.latitude && message.location.coordinate.longitude == userLocationAnnotation.coordinate.longitude);
  
  if (message.location && message && (!sameCoordinate && !self.statusLocationMapView.hidden)) {
    self.statusLocationMapView.hidden = NO;
    
    // Modify height constraint
    NSLayoutConstraint *heightConstraint;
    for (NSLayoutConstraint *constraint in self.statusLocationMapView.constraints) {
      if (constraint.firstAttribute == NSLayoutAttributeHeight) {
        heightConstraint = constraint;
        break;
      }
    }
    
    heightConstant = heightConstraint.constant;
    heightConstraint.constant = (heightConstraint.constant == 0) ? heightConstant : heightConstraint.constant;
    
    // Remove existing pin and just update the necessry info
    if (userLocationAnnotation) {
      [self.statusLocationMapView removeAnnotation:userLocationAnnotation];
      
    } else {
      // Create new Pin
      userLocationAnnotation = [MKPointAnnotation new];
      userLocationAnnotation.title = (self.isCurrentUser) ? @"Your Public Location" : [NSString stringWithFormat:@"%@'s Location", self.profileUser.firstName];
    }
    
    userLocationAnnotation.coordinate = message.location.coordinate;
    
    [self.statusLocationMapView addAnnotation:userLocationAnnotation];
    
    // Zoom on Pin
    MKCoordinateRegion region;
    MKCoordinateSpan span;
    span.latitudeDelta = 0.01;
    span.longitudeDelta = 0.01;
    region.span = span;
    region.center = message.location.coordinate;
    
    region = [self.statusLocationMapView regionThatFits:region];
    [self.statusLocationMapView setRegion:region animated:YES];
    
  } else if (!message) {
    // Modify height constraint
    NSLayoutConstraint *heightConstraint;
    for (NSLayoutConstraint *constraint in self.statusLocationMapView.constraints) {
      if (constraint.firstAttribute == NSLayoutAttributeHeight) {
        heightConstraint = constraint;
        break;
      }
    }
    
    heightConstant = heightConstraint.constant;
    heightConstraint.constant = 0;
    
    self.statusLocationMapView.hidden = YES;
  }
  
  [self.view updateConstraints];
  
  // Based on if not current user
  if (!self.isCurrentUser) {
    
    // Secondary button
    if ([[ContactsManager sharedInstance] contactBlockedCurrentUser:self.profileUser]) {
      [self.secondaryButton setImage:[UIImage imageNamed:@"Blocked"] forState:UIControlStateNormal];
      
    } else if ([[ContactsManager sharedInstance] currentUserBlockedContact:self.profileUser]) {
      [self.secondaryButton setImage:[UIImage imageNamed:@"Unblock Person"] forState:UIControlStateNormal];
      [self.secondaryButton addTarget:self action:@selector(toggleBlock) forControlEvents:UIControlEventTouchUpInside];
      
    } else {
      [self.secondaryButton setImage:[UIImage imageNamed:@"Block Person"] forState:UIControlStateNormal];
      [self.secondaryButton addTarget:self action:@selector(toggleBlock) forControlEvents:UIControlEventTouchUpInside];

    }
    
    // Favorite
    if ([[DUser currentUser].favouriteContacts containsObject:self.profileUser.recordID]) {
      // Already favorited
      [self.favoriteButton setImage:[UIImage imageNamed:@"Favorite Selected"] forState:UIControlStateNormal];
      [self.favoriteButton setTitle:[NSString stringWithFormat:@"     Remove %@ from Favorites", self.profileUser.firstName] forState:UIControlStateNormal];
      
    } else {
      // Not Already favorited
      [self.favoriteButton setImage:[UIImage imageNamed:@"Favorite Deselected"] forState:UIControlStateNormal];
      [self.favoriteButton setTitle:[NSString stringWithFormat:@"     Add %@ to Favorites", self.profileUser.firstName] forState:UIControlStateNormal];
    }
    
    // Send update text
    self.sendUpdateLabel.text = [NSString stringWithFormat:@"Send %@ an Update", self.profileUser.firstName];
    
    // Request Button
    NSString *key = [NSString stringWithFormat:@"lastStatusRequest%@", self.profileUser.recordID];
    NSDate *lastRequestDate = [NSUserDefaults.standardUserDefaults objectForKey:key];
    
    if (-[lastRequestDate timeIntervalSinceNow] <= 600 && lastRequestDate) {
      // Disable the button, change the text and reenable it in 10 mins.
      self.requestStatusButton.enabled = NO;
      [self.requestStatusButton setTitle:@"Wait a bit before asking again" forState:UIControlStateNormal];
      
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(-[lastRequestDate timeIntervalSinceNow] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.requestStatusButton.enabled = YES;
        [self.requestStatusButton setTitle:[NSString stringWithFormat:@"     What's up %@?", self.profileUser.firstName] forState:UIControlStateNormal];
      });
      
    } else {
      [self.requestStatusButton setTitle:[NSString stringWithFormat:@"     What's up %@?", self.profileUser.firstName] forState:UIControlStateNormal];
    }
    
  } else {// It's the current user
    // Secondary button - Email
    [self.secondaryButton setTitle:@"" forState:UIControlStateNormal];
    [self.secondaryButton setImage:nil forState:UIControlStateNormal];

    // Send update text
    self.sendUpdateLabel.text = @"Compose a new Update";
  }
  
  // Profile Image
  [self.profileImageView setImage:[UIImage imageWithData:self.profileUser.profileImageData]];
  
  // Name label
  [self.nameLabel setText:[NSString stringWithFormat:@"%@ %@", self.profileUser.firstName, self.profileUser.lastName]];
  
  // Round Profile Image
  self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width/2;
  
  // ScrollView contentsize and insets
  [self updateScrollviewContentSizeAndInsets];
}

- (void)updateScrollviewContentSizeAndInsets {
  // Set the content size and insets of the scroll view
  float topInset = (self.toolbar) ? self.toolbar.frame.size.height : self.navigationController.navigationBar.frame.size.height+20;
  self.scrollView.contentInset = UIEdgeInsetsMake(topInset, 0, 0, 0);
  
  float contentSizeHeight = self.composeUpdateButton.frame.origin.y + self.composeUpdateButton.frame.size.height - topInset - self.tabBarController.tabBar.frame.size.height;
  if (!self.statusLocationMapView.hidden) contentSizeHeight += heightConstant;
  
  self.scrollView.contentSize = CGSizeMake(self.statusLocationMapView.frame.size.width, contentSizeHeight);
}

#pragma mark - Actions
- (IBAction)requestStatus:(id)sender {
  BOOL requested = [[ContactsManager sharedInstance] requestStatusForContact:self.profileUser];
  
  if (requested) {
    NSString *key = [NSString stringWithFormat:@"lastStatusRequest%@", self.profileUser.recordID];
    NSDate *lastRequestDate = [NSUserDefaults.standardUserDefaults objectForKey:key];

    // Disable the button, change the text and reenable it in 10 mins.
    self.requestStatusButton.enabled = NO;
    [self.requestStatusButton setTitle:@"Wait a bit before asking again" forState:UIControlStateNormal];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(-[lastRequestDate timeIntervalSinceNow] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      self.requestStatusButton.enabled = YES;
      [self.requestStatusButton setTitle:[NSString stringWithFormat:@"     What's up %@?", self.profileUser.firstName] forState:UIControlStateNormal];
    });
  }
  
  UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Asked" message:@"Dude, we told them you'd like to find out about what they're doing." preferredStyle:UIAlertControllerStyleAlert];
  [ac addAction:[UIAlertAction actionWithTitle:@"Sweet!" style:UIAlertActionStyleDefault handler:nil]];
  
  [self presentViewController:ac animated:YES completion:nil];
}

- (void)toggleBlock {
  // No multiple presses
  [self.secondaryButton setEnabled:NO];
  
  // Asyncly perform the action (block/unblock)
  NSBlockOperation *toggleBlockOperation = [NSBlockOperation blockOperationWithBlock:^{
    if ([[ContactsManager sharedInstance] currentUserBlockedContact:self.profileUser]) {
      [[ContactsManager sharedInstance] unblockContact:self.profileUser];
      
    } else {
      [[ContactsManager sharedInstance] blockContact:self.profileUser];
    }
  }];
  
  toggleBlockOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
  toggleBlockOperation.qualityOfService = NSQualityOfServiceUserInitiated;
  
  toggleBlockOperation.completionBlock = ^{
    dispatch_async(dispatch_get_main_queue(), ^{
      // Update the image
      if ([[ContactsManager sharedInstance] contactBlockedCurrentUser:self.profileUser]) {
        [self.secondaryButton setImage:[UIImage imageNamed:@"Blocked"] forState:UIControlStateNormal];
        
      } else if ([[ContactsManager sharedInstance] currentUserBlockedContact:self.profileUser]) {
        [self.secondaryButton setImage:[UIImage imageNamed:@"Unblock Person"] forState:UIControlStateNormal];
        [self.secondaryButton addTarget:self action:@selector(toggleBlock) forControlEvents:UIControlEventTouchUpInside];
        
      } else {
        [self.secondaryButton setImage:[UIImage imageNamed:@"Block Person"] forState:UIControlStateNormal];
        [self.secondaryButton addTarget:self action:@selector(toggleBlock) forControlEvents:UIControlEventTouchUpInside];
      }
      
      [self.secondaryButton setEnabled:YES];
    });
  };
  
  [[[NSThread alloc] initWithTarget:toggleBlockOperation selector:@selector(start) object:nil] start];
}

- (IBAction)toggleFavorite:(id)sender {
  // No multiple presses
  [self.favoriteButton setEnabled:NO];
  
  // Asyncly perform the action (favorite/unfavorite)
  NSBlockOperation *toggleFavoriteOperation = [NSBlockOperation blockOperationWithBlock:^{
    if ([[DUser currentUser].favouriteContacts containsObject:self.profileUser.recordID]) {
      // Already favorited
      [[ContactsManager sharedInstance] removeContactFromFavourites:self.profileUser];
      
    } else {
      // Not Already favorited
      [[ContactsManager sharedInstance] addContactToFavourites:self.profileUser];
    }
  }];
  
  toggleFavoriteOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
  toggleFavoriteOperation.qualityOfService = NSQualityOfServiceUserInitiated;
  
  toggleFavoriteOperation.completionBlock = ^{
    dispatch_async(dispatch_get_main_queue(), ^{
      // Update the image
      if ([[DUser currentUser].favouriteContacts containsObject:self.profileUser.recordID]) {
        [self.favoriteButton setImage:[UIImage imageNamed:@"Favorite Selected"] forState:UIControlStateNormal];
        [self.favoriteButton setTitle:[NSString stringWithFormat:@"     Remove %@ from Favorites", self.profileUser.firstName] forState:UIControlStateNormal];
        
      } else {
        [self.favoriteButton setImage:[UIImage imageNamed:@"Favorite Deselected"] forState:UIControlStateNormal];
        [self.favoriteButton setTitle:[NSString stringWithFormat:@"     Add %@ to Favorites", self.profileUser.firstName] forState:UIControlStateNormal];
      }
      
      [self.favoriteButton setEnabled:YES];
    });
  };
  
  [[[NSThread alloc] initWithTarget:toggleFavoriteOperation selector:@selector(start) object:nil] start];
}

- (IBAction)composeUpdate:(id)sender {
  [self performSegueWithIdentifier:@"showMessages" sender:(!self.isCurrentUser) ? self.profileUser : nil];
}

- (IBAction)editProfileImage:(id)sender {
  UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"Choose a profile picture from" message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
  
  [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    [actionSheet dismissViewControllerAnimated:YES completion:nil];
  }]];
  
  [actionSheet addAction:[UIAlertAction actionWithTitle:@"Camera" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    UIImagePickerController *picker = [UIImagePickerController new];
    picker.delegate = self;
    picker.allowsEditing = YES;
    
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentViewController:picker animated:YES completion:nil];
    
  }]];
  
  [actionSheet addAction:[UIAlertAction actionWithTitle:@"Library" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    UIImagePickerController *picker = [UIImagePickerController new];
    picker.delegate = self;
    picker.allowsEditing = YES;
    
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:picker animated:YES completion:nil];
    
  }]];
  
  [self presentViewController:actionSheet animated:YES completion:nil];
}

- (IBAction)toggleFullscreenProfileImage:(id)sender {
  CGRect fullscreenRect = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height-64-self.tabBarController.tabBar.frame.size.height);
  
  // Toggle fullscreen when profile image view clicked (only in non current user)
  if (CGRectEqualToRect(self.profileImageView.frame, fullscreenRect)) {
    [self.profileImageView setContentMode:UIViewContentModeScaleAspectFit];
    
    [UIView animateWithDuration:0.3 animations:^{
      [self.profileImageView setFrame:originalProfileImageViewFrame];
      self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width/2;
      
    } completion:^(BOOL finished) {
      UIScrollView *scrollView = (UIScrollView *)self.profileImageView.superview;
      scrollView.scrollEnabled = YES;
    }];
    
  } else {
    [self.profileImageView setContentMode:UIViewContentModeScaleAspectFit];
    
    originalProfileImageViewFrame = self.profileImageView.frame;
    
    [UIView animateWithDuration:0.3 animations:^{
      [self.profileImageView setFrame:fullscreenRect];
      
    } completion:^(BOOL finished) {
      self.profileImageView.layer.cornerRadius = 0;
      
      UIScrollView *scrollView = (UIScrollView *)self.profileImageView.superview;
      scrollView.scrollEnabled = NO;
    }];
  }
}

#pragma mark - UIImagePickerController
- (void)imagePickerControllerDidCancel:(UIImagePickerController*)picker {
  [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(nonnull NSDictionary<NSString *,id> *)info {
  [picker dismissViewControllerAnimated:YES completion:nil];
  
  UIImage *selectedImage = info[UIImagePickerControllerEditedImage];
  UIImage *thumbnailImage = [selectedImage imageByScalingAndCroppingForSize:CGSizeMake(200, 200)];
  
  // Set user image file
  NSData *selectedImageData = UIImageJPEGRepresentation(thumbnailImage, 1);
  
  if (selectedImageData) {
    self.profileUser.profileImageData = selectedImageData;
    [self.profileImageView setImage:thumbnailImage];
  
  } else {
#warning handle error
    NSLog(@"No image data for selected image. wut.");
  }
  
  [self.profileUser saveWithCompletion:^(CKRecord * _Nullable record, NSError * _Nullable error) {
    if (error) {
#warning handle
      NSLog(@"Error saving image: %@", error);
    
    } else {
      self.profileUser = [DUser currentUser];
      [self updateProfileInterface];
    }
  }];
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([segue.identifier isEqualToString:@"showMessages"]) {
    UINavigationController *navigationVC = [segue destinationViewController];
    MessagesTableViewController *messagesTableViewController  = (MessagesTableViewController*)navigationVC.visibleViewController;
    messagesTableViewController.selectedUsers = (sender) ? @[sender] : @[];
    messagesTableViewController.shareOnDudeDefault = (!sender);
  }
}

#pragma mark - Status Bar
- (BOOL)prefersStatusBarHidden {return NO;}
- (UIStatusBarStyle)preferredStatusBarStyle {return UIStatusBarStyleLightContent;}

@end
