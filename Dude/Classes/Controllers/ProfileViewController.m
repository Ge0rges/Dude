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

@interface ProfileViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate> {
  CGRect originalProfileImageViewFrame;
  CGFloat heightConstant;
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

@end

@implementation ProfileViewController
- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  
  // Update status bar
  [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  // Update UI
  [self updateProfileInterface];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  // Tell the delegate we are the visible view
  AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
  appDelegate.visibleViewController = self;
}

#pragma mark - Ui
- (void)updateProfileInterface {
  // Status Update
  DMessage *message = [[ContactsManager sharedInstance] latestMessageForContact:(self.profileUser)?: [DUser currentUser]];
  
  
  NSString *locationErrorText = ([self.profileUser isEqual:[DUser currentUser]]) ? @"Dude, you didn't share a location yet" : @"Dude, you didn't share a location yet";
  NSString *lastSeenErrorText = ([self.profileUser isEqual:[DUser currentUser]]) ? @"Dude, you didn't share an update yet" : @"Dude, you didn't share an update yet";
  
  NSString *locationText = [NSString stringWithFormat:@"%@ - %@", message.city, message.timestamp];
  
  self.locationLabel.text = (message.city && message.timestamp) ? locationText : locationErrorText;
  self.statusLabel.text = (message.lastSeen) ? message.lastSeen : lastSeenErrorText;
  
  // Map
  if (message.location && message) {
    // modify height constraint
    NSLayoutConstraint *heightConstraint;
    for (NSLayoutConstraint *constraint in self.statusLocationMapView.constraints) {
      if (constraint.firstAttribute == NSLayoutAttributeHeight) {
        heightConstraint = constraint;
        break;
      }
    }
    
    heightConstraint.constant = heightConstant;
    
    // Add Pin
    MKPointAnnotation *annotation = [MKPointAnnotation new];
    annotation.coordinate = message.location.coordinate;
    annotation.title = (self.profileUser) ? [NSString stringWithFormat:@"%@'s Location", [self.profileUser.fullName stringBetweenString:@"" andString:@" "]] : @"Your Public Location";
    [self.statusLocationMapView addAnnotation:annotation];
    
    // Zoom on Pin
    MKCoordinateRegion region;
    MKCoordinateSpan span;
    span.latitudeDelta = 0.01;
    span.longitudeDelta = 0.01;
    region.span = span;
    region.center = message.location.coordinate;
    
    [self.statusLocationMapView setRegion:region animated:TRUE];
    [self.statusLocationMapView regionThatFits:region];
    
  } else {
    // modify height constraint
    NSLayoutConstraint *heightConstraint;
    for (NSLayoutConstraint *constraint in self.statusLocationMapView.constraints) {
      if (constraint.firstAttribute == NSLayoutAttributeHeight) {
        heightConstraint = constraint;
        break;
      }
    }
    
    heightConstant = heightConstraint.constant;
    heightConstraint.constant = 0;
  }
  
  // Variable
  if (self.profileUser) {
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
    if ([[DUser currentUser].favouriteContactsEmails containsObject:self.profileUser.email.lowercaseString]) {
      // Already favorited
      [self.favoriteButton setImage:[UIImage imageNamed:@"Favorite Selected"] forState:UIControlStateNormal];
      [self.favoriteButton setTitle:[NSString stringWithFormat:@"     Remove %@ from Favorites", self.profileUser.fullName] forState:UIControlStateNormal];
      
    } else {
      // Not Already favorited
      [self.favoriteButton setImage:[UIImage imageNamed:@"Favorite Deselected"] forState:UIControlStateNormal];
      [self.favoriteButton setTitle:[NSString stringWithFormat:@"     Add %@ to Favorites", self.profileUser.fullName] forState:UIControlStateNormal];
    }
    
    // Profile Image
    [self.profileImageView sd_setImageWithURL:[NSURL URLWithString:self.profileUser.profileImage.url] placeholderImage:[UIImage imageNamed:@"Default Profile Image"]];
    
    // Name label
    [self.nameLabel setText:self.profileUser.fullName];
    
    // Send update text
    self.sendUpdateLabel.text = [NSString stringWithFormat:@"Send %@ an Update", self.profileUser.fullName];
    
  } else {// Current user    
    // Secondary button - Email
    [self.secondaryButton setTitle:[DUser currentUser].email forState:UIControlStateNormal];
    
    // Profile Image
    [self.profileImageView sd_setImageWithURL:[NSURL URLWithString:[DUser currentUser].profileImage.url] placeholderImage:[UIImage imageNamed:@"Default Profile Image"]];
    
    // Name label
    [self.nameLabel setText:[DUser currentUser].fullName];
    
    // Send update text
    self.sendUpdateLabel.text = @"Compose a new Update";
  }
}

#pragma mark - Actions
- (IBAction)requestStatus:(id)sender {
  BOOL requested = [[ContactsManager sharedInstance] requestStatusForContact:self.profileUser inBackground:YES];
  
  UIButton *requestStatusButton = (UIButton*)sender;
  requestStatusButton.enabled = NO;
  
  UIAlertController *ac = [UIAlertController alertControllerWithTitle:(requested) ? @"Status Requested" : @"Status not Requested" message:(requested) ? @"Dude, informed them you'd like to know what they're doing." : @"Sorry Dude, but you can't request statuses more then once in under 10 minutes." preferredStyle:UIAlertControllerStyleAlert];
  [ac addAction:[UIAlertAction actionWithTitle:(requested) ? @"Great!" : @"Okay, I'll ask again later" style:UIAlertActionStyleDefault handler:nil]];
  
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
    if ([[DUser currentUser].favouriteContactsEmails containsObject:self.profileUser.email.lowercaseString]) {
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
      if ([[DUser currentUser].favouriteContactsEmails containsObject:self.profileUser.email.lowercaseString]) {
        [self.favoriteButton setImage:[UIImage imageNamed:@"Favorite Selected"] forState:UIControlStateNormal];
        [self.favoriteButton setTitle:[NSString stringWithFormat:@"     Remove %@ from Favorites", self.profileUser.fullName] forState:UIControlStateNormal];
      
      } else {
        [self.favoriteButton setImage:[UIImage imageNamed:@"Favorite Deselected"] forState:UIControlStateNormal];
        [self.favoriteButton setTitle:[NSString stringWithFormat:@"     Add %@ to Favorites", self.profileUser.fullName] forState:UIControlStateNormal];
      }
      
      [self.favoriteButton setEnabled:YES];
    });
  };
  
  [[[NSThread alloc] initWithTarget:toggleFavoriteOperation selector:@selector(start) object:nil] start];
}

- (IBAction)composeUpdate:(id)sender {
  [self performSegueWithIdentifier:@"showMessages" sender:self.profileUser];
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
  // Toggle fullscreen when profile image view clicked (only in non current user)
  if (CGRectEqualToRect(self.profileImageView.frame, self.view.frame)) {
    [self.profileImageView setContentMode:UIViewContentModeScaleAspectFit];

    [UIView animateWithDuration:0.3 animations:^{
      [self.profileImageView setFrame:originalProfileImageViewFrame];
    }];

  } else {
    [self.profileImageView setContentMode:UIViewContentModeScaleAspectFit];

    originalProfileImageViewFrame = self.profileImageView.frame;
    
    [UIView animateWithDuration:0.3 animations:^{
      [self.profileImageView setFrame:self.view.frame];
    }];
  }
}

- (IBAction)changeEmail {
#warning implement
}

- (IBAction)logout:(id)sender {
  [DUser logOut];
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIImagePickerController
- (void)imagePickerControllerDidCancel:(UIImagePickerController*)picker {
  [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary*)info {
  [picker dismissViewControllerAnimated:YES completion:nil];
  
  UIImage *selectedImage = info[UIImagePickerControllerEditedImage];
  UIImage *thumbnailImage = [selectedImage imageByScalingAndCroppingForSize:CGSizeMake(200, 200)];
  
  // Set user image file
  PFFile *selectedImageFile = [PFFile fileWithData:UIImageJPEGRepresentation(thumbnailImage, 1)];
  
  if (selectedImageFile) {
    [[DUser currentUser] setProfileImage:selectedImageFile];
    [self.profileImageView setImage:thumbnailImage];
    
  }
  
  [[DUser currentUser] saveInBackground];
}

#pragma mark - Status Bar
- (BOOL)prefersStatusBarHidden {return NO;}
- (UIStatusBarStyle)preferredStatusBarStyle {return UIStatusBarStyleLightContent;}

@end
