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
  if ([DUser currentUser]) {
    [self dismissViewControllerAnimated:YES completion:nil];
  }
  
  // Tell the delegate we are the visible view
  AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
  appDelegate.visibleViewController = self;
}

#pragma mark - Navigation
- (IBAction)unwindToWelcomeViewController:(UIStoryboardSegue*)segue {}

- (void)performSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
  [[CKContainer defaultContainer] accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus, NSError *error) {
    if (accountStatus == CKAccountStatusNoAccount) {
      UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Sign in to iCloud"
                                                                     message:@"Sign in to your iCloud account to write records. On the Home screen, launch Settings, tap iCloud, and enter your Apple ID. Turn iCloud Drive on. If you don't have an iCloud account, tap Create a new Apple ID."
                                                              preferredStyle:UIAlertControllerStyleAlert];
      [alert addAction:[UIAlertAction actionWithTitle:@"Okay"
                                                style:UIAlertActionStyleCancel
                                              handler:nil]];
      [self presentViewController:alert animated:YES completion:nil];
   
    } else if (accountStatus == CKAccountStatusRestricted) {
      UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Dude ask your parents"
                                                                     message:@"Hey little Dude, seems like your parents have disabled access to your iCloud account with Parental Controls. Dude relies on iCloud to function, ask your parents to remove the restriction and try again."
                                                              preferredStyle:UIAlertControllerStyleAlert];
      [alert addAction:[UIAlertAction actionWithTitle:@"Will do!"
                                                style:UIAlertActionStyleCancel
                                              handler:nil]];
      [self presentViewController:alert animated:YES completion:nil];
      
    } else{
      [super performSegueWithIdentifier:identifier sender:sender];
    }
  }];
}

#pragma mark - Status Bar
- (BOOL)prefersStatusBarHidden {return NO;}
- (UIStatusBarStyle)preferredStatusBarStyle {return UIStatusBarStyleDefault;}

@end
