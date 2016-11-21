//
//  WelcomeViewController.m
//  Dude
//
//  Created by Georges Kanaan on 23/08/2015.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

#import "WelcomeViewController.h"

// Controllers
#import "SignUpViewController.h"

// Managers
#import "CloudKitManager.h"

// Classes
#import "SlidingSegues.h"

//Models
#import "DUser.h"

// Constants
#import "Constants.h"

@interface WelcomeViewController ()

@end

@implementation WelcomeViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  // Update status bar
  [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:YES];

  [CloudKitManager fetchCurrentUserWithSuccessBlock:^(CKRecord * _Nullable currentUserRecord) {
    if (currentUserRecord) {
      [self dismissViewControllerAnimated:YES completion:nil];
    }
  } failureBlock:nil preferCache:YES];
  
  
  // Tell the delegate we are the visible view
  AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
  appDelegate.visibleViewController = self;
  
  // iCloud account permission
  [[CKContainer defaultContainer] accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus, NSError *error) {
    if (accountStatus == CKAccountStatusNoAccount || accountStatus == CKAccountStatusCouldNotDetermine) {
      UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Dude, Sign in to iCloud"
                                                                     message:@"Sign in to your iCloud account to use Dude. On the Home screen, launch Settings, tap iCloud, and enter your Apple ID. Turn iCloud Drive on. If you don't have an iCloud account, tap Create a new Apple ID."
                                                              preferredStyle:UIAlertControllerStyleAlert];
      
      [alert addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:nil]];
      [self presentViewController:alert animated:YES completion:nil];
      
    } else if (accountStatus == CKAccountStatusRestricted) {
      UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Dude ask your parents"
                                                                     message:@"Hey little Dude, seems like your parents have disabled access to your iCloud account with Parental Controls. Dude relies on iCloud to function, ask your parents to remove the restriction and try again."
                                                              preferredStyle:UIAlertControllerStyleAlert];
      
      [alert addAction:[UIAlertAction actionWithTitle:@"Will do!" style:UIAlertActionStyleCancel handler:nil]];
      [self presentViewController:alert animated:YES completion:nil];
      
    }
  }];
}

#pragma mark - Navigation
- (IBAction)unwindToWelcomeViewController:(UIStoryboardSegue*)segue {}

#pragma mark - Status Bar
- (BOOL)prefersStatusBarHidden {return NO;}
- (UIStatusBarStyle)preferredStatusBarStyle {return UIStatusBarStyleDefault;}

@end
