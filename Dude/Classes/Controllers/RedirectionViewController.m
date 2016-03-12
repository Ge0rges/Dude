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
#import "Reachability.h"

// Models
#import "DUser.h"

@interface RedirectionViewController ()

@property (retain, nonatomic)  Reachability *networkReachability;

@end

@implementation RedirectionViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.

  // Prepare reachibility
  internetConnectionViewIsShowing = NO;
  
  self.networkReachability = [Reachability reachabilityForInternetConnection];
  
  // Update status bar
  [self setNeedsStatusBarAppearanceUpdate];
  
  // Set transition animation
  self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  // Keep checking for internet connection
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkConnection:) name:kReachabilityChangedNotification object:nil];
  [self.networkReachability startNotifier];

  // Tell the delegate we are the visible view
  AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
  appDelegate.visibleViewController = self;
    
  // Redirect the app to the correct View Controller if we have an internet connection in the first place
  if ([self.networkReachability currentReachabilityStatus] != NotReachable) {// Check if we have internet
    if ([DUser currentUser].isAuthenticated && [DUser currentUser].sessionToken) {
      // Fetch the latest currentUser
      [[DUser currentUser] fetchInBackgroundWithBlock:nil];
      [self performSegueWithIdentifier:@"mainSegue" sender:nil];
      
    } else  {// User isn't authenticated
      // Clear keychain to prevent issues
      [DUser logOut];
      
      // Show the log/sign in view
      [self performSegueWithIdentifier:@"welcomeSegue" sender:nil];
      
    }
  } else {// No internet
    [self checkConnection:nil];
  }
}

- (void)checkConnection:(NSNotification*)notification {
  // Check if we have internet
  if ([self.networkReachability currentReachabilityStatus] == NotReachable && !internetConnectionViewIsShowing) {
    UIViewController *noInternetVC = [self.storyboard instantiateViewControllerWithIdentifier:@"NoInternetConnectionVC"];
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate.visibleViewController presentViewController:noInternetVC animated:YES completion:^{
      internetConnectionViewIsShowing = YES;
    }];
    
  } else if (internetConnectionViewIsShowing && [self.networkReachability currentReachabilityStatus] != NotReachable){
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate.visibleViewController dismissViewControllerAnimated:YES completion:^{
      internetConnectionViewIsShowing = NO;
    }];
  }
}

#pragma mark - Status Bar
- (BOOL)prefersStatusBarHidden {return NO;}
- (UIStatusBarStyle)preferredStatusBarStyle {return UIStatusBarStyleLightContent;}

@end