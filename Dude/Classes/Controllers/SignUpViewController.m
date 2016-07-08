//
//  SignUpViewController.m
//  Dude
//
//  Created by Georges Kanaan on 6/5/15.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

#import "SignUpViewController.h"

// Classes
#import "AppDelegate.h"

// Frameworks
#import <Accounts/Accounts.h>
#import <CloudKit/CloudKit.h>

// Models
#import "DUser.h"

// Extensions & Categories
#import "UIImageExtensions.h"

// Utils
#import "Constants.h"


@interface SignUpViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate> {
  NSData *profileImageData;
  
  UIImageView *retakeImageView;  
}

@property (strong, nonatomic) IBOutlet UILabel *stepLabel;
@property (strong, nonatomic) IBOutlet UILabel *titleStepLabel;

@property (strong, nonatomic) IBOutlet UITextField *textField;

@property (strong, nonatomic) IBOutlet UIImageView *stepImageView;

@property (strong, nonatomic) IBOutlet UIButton *confirmButton;
@property (strong, nonatomic) IBOutlet UIButton *backButton;

@end

@implementation SignUpViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  
  // Update status bar
  [self setNeedsStatusBarAppearanceUpdate];
  
  // Start a timer to check if the button should be enabled
  [self.textField addTarget:self action:@selector(checkConfirmButton) forControlEvents:UIControlEventEditingChanged];

  // Simulate a first press for initial setup
  [self confirmed:self.confirmButton];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  // Tell the delegate we are the visible view
  AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
  appDelegate.visibleViewController = self;
}

#pragma mark - Steps
- (IBAction)confirmed:(UIButton*)sender {
    switch (self.confirmButton.tag) {
      case 0: {
        // Remove retake X image
        [retakeImageView removeFromSuperview];
        retakeImageView = nil;
        
        [self animateToStepWithInitialScreenshot:[self screenshot] fromRight:YES];
        [self proceedToSocial];
        break;
      }
        
      case 1: {
        // Fetch the current User
        DUser *currentUser = [DUser currentUser];// Cache update
        if (!currentUser) [DUser currentUser];
        
        if (currentUser) {
          UIAlertController *incorrectCredentialsAlertController = [UIAlertController alertControllerWithTitle:@"Dude, we couldn't sign you up" message:@"" preferredStyle:UIAlertControllerStyleAlert];
          [incorrectCredentialsAlertController addAction:[UIAlertAction actionWithTitle:@"Cool, open settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            // Go back to the beginning
            [self animateToStepWithInitialScreenshot:[self screenshot] fromRight:NO];
            [self proceedToPhoto];
            
            self.confirmButton.tag -=5;
          }]];
          
          dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:incorrectCredentialsAlertController animated:YES completion:nil];
          });
          
          
        } else {
          // Go back to the redirection controller
          [self.presentingViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
          
          [currentUser selectFacebookAccountWithCompletion:nil];
          [currentUser selectTwitterAccountWithCompletion:nil];
          
          // Save the user's profile image
          CKRecord *profilePictureRecord = [[CKRecord alloc] initWithRecordType:@"ProfilePicture"];
          profilePictureRecord[@"Picture"] = profileImageData;
          profilePictureRecord[@"Owner"] = [[CKReference alloc] initWithRecordID:currentUser.recordID action:CKReferenceActionDeleteSelf];

          [[[CKContainer defaultContainer] publicCloudDatabase] saveRecord:profilePictureRecord completionHandler:^(CKRecord * _Nullable record, NSError * _Nullable error) {
            if (error) {
              NSLog(@"Well shit. Couldnt upload the profile image.");
            }
          }];
          
          // Subscribe to last seen creation
          NSPredicate *predicate = [NSPredicate predicateWithFormat:@"Receiver = %@", currentUser.recordID];
          CKSubscription *lastSeenSubscription = [[CKSubscription alloc] initWithRecordType:@"LastSeen" predicate:predicate options:CKSubscriptionOptionsFiresOnRecordCreation | CKSubscriptionOptionsFiresOnRecordUpdate];
          
          CKNotificationInfo *lastSeenNotificationInfo = [CKNotificationInfo new];
          lastSeenNotificationInfo.desiredKeys = @[@"Receiver",@"Sender", @"Message"];
          lastSeenNotificationInfo.alertLocalizationArgs = @[@"NotificationAlert"];
          lastSeenNotificationInfo.alertBody = @"%@";
          lastSeenNotificationInfo.shouldBadge = YES;
          lastSeenNotificationInfo.category = @"REPLY_CATEGORY";
          
          [lastSeenSubscription setNotificationInfo:lastSeenNotificationInfo];
          
          [[[CKContainer defaultContainer] publicCloudDatabase] saveSubscription:lastSeenSubscription completionHandler:^(CKSubscription *subscription, NSError *error) {
            if (error) {
              NSLog(@"Well shit. subscription didnt donkey.");
            }
          }];
          
          // Subscribe to notification creation
          CKSubscription *notificationSubscription = [[CKSubscription alloc] initWithRecordType:@"Notification" predicate:predicate options:CKSubscriptionOptionsFiresOnRecordCreation];
          
          CKNotificationInfo *notificationInfo = [CKNotificationInfo new];
          notificationInfo.alertLocalizationArgs = @[@"Message"];
          notificationInfo.alertBody = @"%@";
          notificationInfo.shouldBadge = NO;
          
          [notificationSubscription setNotificationInfo:notificationInfo];
          
          [[[CKContainer defaultContainer] publicCloudDatabase] saveSubscription:notificationSubscription completionHandler:^(CKSubscription *subscription, NSError *error) {
            if (error) {
              NSLog(@"Well shit. subscription didnt donkey.");
            }
          }];
          
#pragma mark DEVELOPER ONLY
#if 1
          // Subscribe to notification creation
          NSPredicate *devPredicate = [NSPredicate predicateWithFormat:@"Developer = %@", @YES];
          CKSubscription *devNotificationSubscription = [[CKSubscription alloc] initWithRecordType:@"Notification" predicate:devPredicate options:CKSubscriptionOptionsFiresOnRecordCreation];
          
          CKNotificationInfo *devNotificationInfo = [CKNotificationInfo new];
          devNotificationInfo.alertLocalizationArgs = @[@"Message"];
          devNotificationInfo.alertBody = @"%@ - Remember to delete the record!";
          devNotificationInfo.shouldBadge = YES;
          
          [devNotificationSubscription setNotificationInfo:notificationInfo];
          
          [[[CKContainer defaultContainer] publicCloudDatabase] saveSubscription:devNotificationSubscription completionHandler:^(CKSubscription *subscription, NSError *error) {
            if (error) {
              NSLog(@"Well shit. subscription didnt donkey.");
            }
          }];
#endif

        }
      }
    }

  // Initial check for next step
  [self checkConfirmButton];
}

- (void)proceedToSocial {
  // Update UI
  [self.stepImageView setImage:[UIImage imageNamed:@"Coumpound Social"]];
  [self.stepLabel setText:@"We only use your Twitter and Facebook account when you use them to post messages."];
  [self.titleStepLabel setText:@"Accounts"];
  
  [self.textField setHidden:YES];
  
  [self.confirmButton setTitle:@"ASK ME" forState:UIControlStateNormal];
  [self.backButton setTitle:@" Photo" forState:UIControlStateNormal];
  
  self.confirmButton.tag++;
  
  [self.stepImageView removeGestureRecognizer:self.stepImageView.gestureRecognizers[0]];
  
  [self.textField resignFirstResponder];
  
  [retakeImageView removeFromSuperview];
  retakeImageView = nil;
  
  self.stepImageView.layer.cornerRadius = 0;
  self.stepImageView.clipsToBounds = NO;
}

- (void)proceedToPhoto {
  // Prepare for animation
  [self screenshot];
  
  // Update UI
  [self.stepImageView setImage:[UIImage imageNamed:@"Add Photo"]];
  [self.stepLabel setText:@"Your profile photo will be visible to other users. Smile!"];
  [self.titleStepLabel setText:@"Profile Photo"];
  
  [self.textField setHidden:YES];
  
  [self.confirmButton setTitle:@"CONTINUE" forState:UIControlStateNormal];
  [self.backButton setTitle:@" Password" forState:UIControlStateNormal];
  
  self.confirmButton.tag++;
  
  UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectPicture)];
  [self.stepImageView addGestureRecognizer:tapGestureRecognizer];
  
  [self.textField resignFirstResponder];
  
  [retakeImageView removeFromSuperview];
  retakeImageView = nil;
  
  self.stepImageView.layer.cornerRadius = 0;
  self.stepImageView.clipsToBounds = NO;
  
  profileImageData = nil;
}

#pragma mark - Animation
- (UIImage*)screenshot {
  CGSize imageSize = CGSizeZero;
  
  UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
  if (UIInterfaceOrientationIsPortrait(orientation)) {
    imageSize = [UIScreen mainScreen].bounds.size;
    
  } else {
    imageSize = CGSizeMake([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
  }
  
  UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
  CGContextRef context = UIGraphicsGetCurrentContext();
  for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, window.center.x, window.center.y);
    CGContextConcatCTM(context, window.transform);
    CGContextTranslateCTM(context, -window.bounds.size.width * window.layer.anchorPoint.x, -window.bounds.size.height * window.layer.anchorPoint.y);
  
    if (orientation == UIInterfaceOrientationLandscapeLeft) {
      CGContextRotateCTM(context, M_PI_2);
      CGContextTranslateCTM(context, 0, -imageSize.width);
    
    } else if (orientation == UIInterfaceOrientationLandscapeRight) {
      CGContextRotateCTM(context, -M_PI_2);
      CGContextTranslateCTM(context, -imageSize.height, 0);
    
    } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
      CGContextRotateCTM(context, M_PI);
      CGContextTranslateCTM(context, -imageSize.width, -imageSize.height);
    }
    
    if ([window respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
      [window drawViewHierarchyInRect:window.bounds afterScreenUpdates:NO];
    
    } else {
      [window.layer renderInContext:context];
    }
    
    CGContextRestoreGState(context);
  }
  
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return image;
}

- (void)animateToStepWithInitialScreenshot:(UIImage*)screenshot fromRight:(BOOL)fromRight {
  if (fromRight) {
    __block UIImageView *sourceImageView = [[UIImageView alloc] initWithImage:screenshot];
    __block UIView *destinationView = self.view;
    
    // Prepare the views locations
    [self.view.superview addSubview:sourceImageView];
    [self.view.superview bringSubviewToFront:sourceImageView];
    
    sourceImageView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    destinationView.transform = CGAffineTransformMakeTranslation(sourceImageView.frame.size.width, 0);

    // Prepare the source controller
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
      destinationView.transform = CGAffineTransformMakeTranslation(0, 0);
      sourceImageView.transform = CGAffineTransformMakeTranslation(-sourceImageView.frame.size.width, 0);
      
    } completion:^(BOOL finished) {
      [sourceImageView removeFromSuperview];
      sourceImageView = nil;
    }];
    
  } else {
    __block UIImageView *sourceImageView = [[UIImageView alloc] initWithImage:screenshot];
    __block UIView *destinationView = self.view;
    
    // Prepare the views locations
    [self.view.superview addSubview:sourceImageView];
    [self.view.superview bringSubviewToFront:sourceImageView];
    
    sourceImageView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    destinationView.transform = CGAffineTransformMakeTranslation(-sourceImageView.frame.size.width, 0);
    
    // Prepare the source controller
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
      destinationView.transform = CGAffineTransformMakeTranslation(0, 0);
      sourceImageView.transform = CGAffineTransformMakeTranslation(sourceImageView.frame.size.width, 0);
      
    } completion:^(BOOL finished) {
      [sourceImageView removeFromSuperview];
      sourceImageView = nil;
    }];
  }
}

#pragma mark - Other
- (BOOL)textFieldShouldReturn:(UITextField*)textField {
  if (self.confirmButton.enabled) {
    [self confirmed:self.confirmButton];
  }
  
  return self.confirmButton.enabled;
}


- (void)checkConfirmButton {
  switch (self.confirmButton.tag) {
    case 1: {
      self.confirmButton.enabled = (profileImageData) ? YES : NO;
      
      break;
    }
      
    case 2: {
      self.confirmButton.enabled = YES;
      break;
    }
  }
  
  self.confirmButton.backgroundColor = (self.confirmButton.enabled) ? self.confirmButton.tintColor : [UIColor lightGrayColor];
}

- (IBAction)back {
  switch (self.confirmButton.tag) {
    case 1: {
      [self.textField resignFirstResponder];
      [self performSegueWithIdentifier:@"unwindToWelcomeViewController" sender:self];
      
      break;
    }
      
    case 2: {
      [self animateToStepWithInitialScreenshot:[self screenshot] fromRight:NO];
        [self proceedToPhoto];
      
      break;
    }
  }
  
  self.confirmButton.tag -= 2;// One to compensate for the ++ the proceed command does and one to actually go back
}

#pragma mark - UIImagePickerController
- (void)selectPicture {
  UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"Now, choose a profile picture from" message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
  
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
  
  [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
  
  [self presentViewController:actionSheet animated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController*)picker {
  [picker dismissViewControllerAnimated:YES completion:^{
    [self checkConfirmButton];
  }];
}

- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary*)info {
  [picker dismissViewControllerAnimated:YES completion:nil];
  
  UIImage *selectedImage = info[UIImagePickerControllerEditedImage];
  UIImage *thumbnailImage = [selectedImage imageByScalingAndCroppingForSize:CGSizeMake(200, 200)];
  
  // Set user image file
  profileImageData = UIImageJPEGRepresentation(thumbnailImage, 1);
  
  if (profileImageData) {
    [self.stepImageView setImage:thumbnailImage];
    
    // Add retake X
    retakeImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Photo Retake"]];
    retakeImageView.frame = CGRectMake(self.stepImageView.frame.origin.x+40, self.stepImageView.frame.origin.y+5, 30, 30);
    retakeImageView.userInteractionEnabled = YES;
    
    [self.view addSubview:retakeImageView];
    
    self.stepImageView.layer.cornerRadius = 100;
    self.stepImageView.clipsToBounds = YES;
    
  } else {
    [self selectPicture];
  }
  
  // For the image
  [self checkConfirmButton];
}

#pragma mark - Status Bar
- (BOOL)prefersStatusBarHidden {return NO;}
- (UIStatusBarStyle)preferredStatusBarStyle {return UIStatusBarStyleDefault;}

@end