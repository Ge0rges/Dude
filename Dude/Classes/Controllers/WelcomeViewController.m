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

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
  SignUpViewController *signUpViewController = (SignUpViewController*)[segue destinationViewController];
  signUpViewController.logIn = ([segue.identifier isEqualToString:@"logInSegue"]) ? YES : NO;
}

@end
