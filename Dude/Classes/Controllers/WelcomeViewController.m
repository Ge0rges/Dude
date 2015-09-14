//
//  WelcomeViewController.m
//  Dude
//
//  Created by Georges Kanaan on 23/08/2015.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

#import "WelcomeViewController.h"
#import "SignUpViewController.h"

@interface WelcomeViewController ()

@end

@implementation WelcomeViewController

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:YES];
  if ([DUser currentUser]) {
    [self dismissViewControllerAnimated:YES completion:nil];
  }
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  SignUpViewController *signUpViewController = (SignUpViewController*)[segue destinationViewController];
  signUpViewController.logIn = ([segue.identifier isEqualToString:@"logInSegue"]) ? YES : NO;
}

@end
