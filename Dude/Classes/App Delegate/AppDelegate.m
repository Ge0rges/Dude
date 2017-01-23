//
//  AppDelegate.m
//  Dude
//
//  Created by Georges Kanaan on 11/20/14.
//  Copyright (c) 2014 Georges Kanaan. All rights reserved.
//

#import "AppDelegate.h"

// Controllers
#import "UsersTableViewController.h"
#import "MessagesTableViewController.h"
#import "ProfileViewController.h"

// Managers
#import "MessagesManager.h"
#import "ContactsManager.h"
#import "WatchConnectivityManager.h"

// Pods
#import "JCNotificationBanner.h"
#import "JCNotificationBannerPresenterIOS7Style.h"

// Models
#import "DUser.h"

// Frameworks
#import <Accounts/Accounts.h>
#import <UserNotifications/UserNotifications.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
  // Override point for customization after application launch.
  
  // Parse setup
  [Parse enableLocalDatastore];// For offline data
  
  // Register our subclass
  [DUser registerSubclass];

  [Parse initializeWithConfiguration:[ParseClientConfiguration configurationWithBlock:^(id<ParseMutableClientConfiguration> configuration) {
    configuration.applicationId = @"fc8a22bb-5ff9-4fff-b114-b6be71619e4a";
    configuration.clientKey = @"";
    configuration.server = @"https://parseapi.buddy.com/parse";
    configuration.localDatastoreEnabled = YES; // Enable local data store
  }]];
  
  
  [PFUser enableRevocableSessionInBackground];
  
  // Register for Push Notifications
  
  // Notification Actions
  UNNotificationAction *resetAction = [UNNotificationAction actionWithIdentifier:@"REPLY_ACTION" title:@"Reply" options:UNNotificationActionOptionForeground];
  
  UNNotificationCategory *replyCategory = [UNNotificationCategory categoryWithIdentifier:@"REPLY_CATEGORY" actions:@[resetAction] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone];
  
  [[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:[NSSet setWithObject:replyCategory]];

  // Start a WCSession to receive messages
  [[WatchConnectivityManager sharedManager] activateSession];
  
  return YES;
}

- (void)applicationWillResignActive:(UIApplication*)application {
  // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication*)application {
  // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
  // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication*)application {
  // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication*)application {
  // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  
  // Start a WCSession to receive messages
  [[WatchConnectivityManager sharedManager] activateSession];
}

- (void)applicationWillTerminate:(UIApplication*)application {
  // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken {
  // Store the deviceToken in the current installation and save it to Parse.
  PFInstallation *currentInstallation = [PFInstallation currentInstallation];
  [currentInstallation setDeviceTokenFromData:deviceToken];
  currentInstallation.channels = @[@"global"];
  
  [currentInstallation saveInBackground];
}

- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo {
  // Get the push data
  NSString *notificationTitle = userInfo[@"aps"][@"alert"][@"title"];
  NSString *notificationMessage = userInfo[@"aps"][@"alert"][@"body"];
  NSString *senderUsername = userInfo[@"username"];
  NSString *senderEmail = userInfo[@"email"];
  
  url = [NSURL URLWithString:userInfo[@"url"]];
  
  double latitude = [userInfo[@"lat"] doubleValue];
  double longitude = [userInfo[@"long"] doubleValue];
  
  // Handle notification
  if (application) {// While in app
    JCNotificationBanner *banner;
    if (url) {
      banner = [[JCNotificationBanner alloc] initWithTitle:notificationTitle message:notificationMessage tapHandler:^{
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
      }];
      
      
    } else if (latitude && longitude) {
      MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude, longitude) addressDictionary:nil];
      mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
      mapItem.name = [NSString stringWithFormat:@"%@'s Location", senderUsername];
      
      banner = [[JCNotificationBanner alloc] initWithTitle:notificationTitle message:notificationMessage tapHandler:^{
        [mapItem openInMapsWithLaunchOptions:nil];
      }];
      
    } else {
      banner = [[JCNotificationBanner alloc] initWithTitle:notificationTitle message:notificationMessage tapHandler:^{
        // Fetch the sender
        PFQuery *senderQuery = [DUser query];
        [senderQuery whereKey:@"email" equalTo:senderEmail];
        
        [senderQuery fromLocalDatastore];
        
        DUser *sender = (DUser*)[senderQuery getFirstObject];
        
        // Present the Profile VC of the user
        ProfileViewController *profileViewController = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"profileVC"];
        profileViewController.profileUser = sender;
        
        [self.visibleViewController presentViewController:profileViewController animated:YES completion:nil];
      }];
      
    }
    
    // Present the notification
    [[JCNotificationBannerPresenterIOS7Style new] presentNotification:banner finished:nil];

    // Move sender to top most in contacts
    DUser *currentUser = [DUser currentUser];

    NSMutableArray *contacts = [currentUser.contactsEmails mutableCopy];
    [contacts removeObject:senderEmail];
    [contacts insertObject:senderEmail atIndex:0];
    
    [currentUser setContactsEmails:[NSSet setWithArray:contacts]];

    // Reload users list
    if ([self.visibleViewController isKindOfClass:[UsersTableViewController class]]) {
      UsersTableViewController *visibleUsersTableVC = (UsersTableViewController*)self.visibleViewController;
      [visibleUsersTableVC performSelectorInBackground:@selector(reloadData:) withObject:nil];
      
    } else if ([self.visibleViewController.presentingViewController isKindOfClass:[UsersTableViewController class]]) {
      UsersTableViewController *visibleUsersTableVC = (UsersTableViewController*)self.visibleViewController.presentingViewController;
      [visibleUsersTableVC performSelectorInBackground:@selector(reloadData:) withObject:nil];
    }
    
  } else {// Regular notification
    if (url) {
      [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
      
    } else if (latitude && longitude) {
      MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude, longitude) addressDictionary:nil];
      mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
      mapItem.name = [NSString stringWithFormat:@"%@'s Location", senderEmail];
      
      [mapItem openInMapsWithLaunchOptions:nil];
      
    } else {
      // Fetch the sender
      PFQuery *senderQuery = [DUser query];
      [senderQuery whereKey:@"email" equalTo:senderEmail];
      
      [senderQuery fromLocalDatastore];
      
      DUser *sender = (DUser*)[senderQuery getFirstObject];
      
      // Present the Profile VC of the user
      ProfileViewController *profileViewController = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"profileVC"];
      profileViewController.profileUser = sender;
      
      [self.visibleViewController presentViewController:profileViewController animated:YES completion:nil];
      
      [PFPush handlePush:userInfo];
    }
  }
}

- (void)application:(UIApplication*)application handleActionWithIdentifier:(NSString*)identifier forRemoteNotification:(NSDictionary*)userInfo completionHandler:(void (^)())completionHandler {
  NSString *senderEmail = userInfo[@"email"];
  
  PFQuery *senderQuery = [DUser query];
  [senderQuery whereKey:@"email" equalTo:senderEmail];
  
  [senderQuery fromLocalDatastore];
  
  DUser *sender = (DUser*)[senderQuery getFirstObject];
  
  MessagesTableViewController *messagesTableViewController = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"MessagesTable"];
  messagesTableViewController.selectedUsers = @[sender];
  
  [self.window.rootViewController.navigationController presentViewController:messagesTableViewController animated:YES completion:nil];
  
  completionHandler();
}

@end
