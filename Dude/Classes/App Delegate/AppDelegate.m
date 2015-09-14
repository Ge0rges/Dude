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

// Managers
#import "MessagesManager.h"
#import "ContactsManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
  // Override point for customization after application launch.
  
  // Parse setup
  [Parse enableLocalDatastore];
  
  // Register our subclass
  [DUser registerSubclass];
  
  // Enable data sharing in app extensions.
  [Parse enableDataSharingWithApplicationGroupIdentifier:@"group.com.ge0rges.Dude"];
  
  [Parse setApplicationId:@"Lwdk0Qnb9755omfrz9Jt1462lzCyzBSTU4lSs37S"
                clientKey:@"bqhjVGFBHTtfjyoRG8WlYBrjqkulOjcilhtQursd"];
  [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
      
  // Register for Push Notifications
  UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound);
  
  // Notification Actions
  UIMutableUserNotificationAction *resetAction = [UIMutableUserNotificationAction new];
  resetAction.identifier = @"REPLY_ACTION";
  resetAction.title = @"Reply";
  resetAction.activationMode = UIUserNotificationActivationModeForeground;
  
  UIMutableUserNotificationCategory *replyCategory = [UIMutableUserNotificationCategory new];
  replyCategory.identifier = @"REPLY_CATEGORY";
  [replyCategory setActions:@[resetAction] forContext:UIUserNotificationActionContextMinimal];
  
  UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes categories:[NSSet setWithObject:replyCategory]];
  
  [application registerUserNotificationSettings:settings];
  [application registerForRemoteNotifications];
  
  // Check if app was opened from a location
  UILocalNotification *notification = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
  if (notification) {
    [self application:application didReceiveRemoteNotification:(NSDictionary*)notification];
  }
  
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
  NSString *title = userInfo[@"aps"][@"alert"][@"title"];
  NSString *notificationMessage = userInfo[@"aps"][@"alert"][@"body"];
  NSString *username = userInfo[@"username"];
  
  url = [NSURL URLWithString:userInfo[@"url"]];
  
  double latitude = [userInfo[@"lat"] doubleValue];
  double longitude = [userInfo[@"long"] doubleValue];
  
#warning figure out in app handling
  // Handle notification
  if (application) {// While in app
#warning badge tab bar and put the recent intop most recent with badge
    if (url) {
    } else if (latitude && longitude) {
      MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude, longitude) addressDictionary:nil];
      mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
      mapItem.name = [NSString stringWithFormat:@"%@'s Location", username];
      
      
    } else {
    }
    
    // Reload users list
    if ([self.visibleViewController isKindOfClass:[UsersTableViewController class]]) {
      UsersTableViewController *visibleUsersTableVC = (UsersTableViewController*)self.visibleViewController;
      [visibleUsersTableVC performSelectorInBackground:@selector(reloadData:) withObject:nil];
      
    } else if ([self.visibleViewController.presentingViewController isKindOfClass:[UsersTableViewController class]]) {
      UsersTableViewController *visibleUsersTableVC = (UsersTableViewController*)self.visibleViewController.presentingViewController;
      [visibleUsersTableVC performSelectorInBackground:@selector(reloadData:) withObject:nil];
    }
    
  } else {
    if (url) {
      [[UIApplication sharedApplication] openURL:url];
      
    } else if (latitude && longitude) {
      MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude, longitude) addressDictionary:nil];
      mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
      mapItem.name = [NSString stringWithFormat:@"%@'s Location", username];
      
      [mapItem openInMapsWithLaunchOptions:nil];
      
    } else {
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
  
  MessagesTableViewController *messagesTableVC = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"MessagesTable"];
  messagesTableVC.selectedUsers = @[sender];
  
  [self.window.rootViewController.navigationController presentViewController:messagesTableVC animated:YES completion:nil];
  
  completionHandler();
}

- (void)application:(UIApplication*)application handleWatchKitExtensionRequest:(NSDictionary*)userInfo reply:(void (^)(NSDictionary*))reply {
  if ([userInfo[WatchRequestsKey] isEqualToString:WatchRequestMessages]) {
    [[MessagesManager sharedInstance] setLocationForMessageGenerationWithCompletion:^(NSError *error) {
      if (error) {
        reply(nil);
        return;
        
      } else {
        MessagesManager *messagesManager = [MessagesManager sharedInstance];
        
        NSArray *messages = [messagesManager generateMessages:15];
        
        reply(@{@"messages": messages});
        
        return;
      }
    }];
    
  } else if ([userInfo[WatchRequestsKey] isEqualToString:WatchRequestSendMessages]) {
    PFQuery *senderQuery = [DUser query];
    [senderQuery whereKey:@"email" equalTo:userInfo[@"senderEmail"]];
    
    [senderQuery fromLocalDatastore];
    
    DUser *receiver = (DUser*)[senderQuery getFirstObject];
    
    [[MessagesManager sharedInstance] sendMessage:userInfo[@"message"] toContact:receiver withCompletion:nil];
  }
}

@end