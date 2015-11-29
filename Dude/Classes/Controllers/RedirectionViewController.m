//
//  RedirectionViewController.m
//  Dude
//
//  Created by Georges Kanaan on 12/9/14.
//  Copyright (c) 2014 Georges Kanaan. All rights reserved.
//

#import "RedirectionViewController.h"

// Classes
#import "AppDelegate.h"

// Controllers
#import "SignUpViewController.h"

// Pods
#import <Reachability/Reachability.h>

// Models
#import "DUser.h"

@interface RedirectionViewController ()

@end

@implementation RedirectionViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  internetConnectionViewIsShowing = NO;
    
  // Update status bar
  [self setNeedsStatusBarAppearanceUpdate];
  
  // Set transition animation
  self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  // check for internet connection
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkConnection:) name:kReachabilityChangedNotification object:nil];
  
  // Redirect the app to the correct VC if we have an internet connection in the first place
  Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
  [networkReachability startNotifier];
  
  // Tell the delegate we are the visible view
  AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  appDelegate.visibleViewController = self;
  
  if ([DUser currentUser].isAuthenticated && [networkReachability isReachable]) {
    // Fetch the latest currentUser
    [[DUser currentUser] fetchInBackgroundWithBlock:^(PFObject *object, NSError *error){
      // Show the main view
      [self performSegueWithIdentifier:@"mainSegue" sender:nil];
    }];
    
  } else if ([networkReachability isReachable]) {
    // Show the log/sign in view
    [self performSegueWithIdentifier:@"welcomeSegue" sender:nil];
  
  } else {
    [self checkConnection:nil];
  }
}

- (void)checkConnection:(NSNotification*)notification {
  // Check if we have internet
  Reachability *networkReachability = [Reachability reachabilityForInternetConnection];

  if (!networkReachability.isReachable && !internetConnectionViewIsShowing) {
    UIViewController *noInternetVC = [self.storyboard instantiateViewControllerWithIdentifier:@"NoInternetConnectionVC"];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.visibleViewController presentViewController:noInternetVC animated:YES completion:^{
      internetConnectionViewIsShowing = YES;
    }];
    
  } else if (internetConnectionViewIsShowing && networkReachability.isReachable){
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.visibleViewController dismissViewControllerAnimated:YES completion:^{
      internetConnectionViewIsShowing = NO;
    }];
  }
}

#pragma mark - Other
- (BOOL)prefersStatusBarHidden {return NO;}
- (UIStatusBarStyle)preferredStatusBarStyle {return UIStatusBarStyleLightContent;}

@end