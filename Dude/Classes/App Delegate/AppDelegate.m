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
#import "DMessage.h"

// Frameworks
#import <Accounts/Accounts.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
  // Override point for customization after application launch.
  
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
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
  [self application:application didReceiveRemoteNotification:userInfo];
  
  completionHandler(UIBackgroundFetchResultNoData);
}

- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo {
  DUser *currentUser = [DUser currentUser];
  CKNotification *notification = [CKNotification notificationFromRemoteNotificationDictionary:userInfo];
  
  if (notification.isPruned) {
    NSLog(@"Notification is pruned use CKFetchNotificationChangesOperation");
  }
  
  CKQueryNotification *queryNotification = [CKQueryNotification notificationFromRemoteNotificationDictionary:userInfo];
  
  DMessage *message = [NSKeyedUnarchiver unarchiveObjectWithData:queryNotification.recordFields[@"Message"]];
  
  if (message) {
    // Update the lastSeen cache
    CKReference *senderReference = queryNotification.recordFields[@"Sender"];
    NSString *lastSeenRecordIDCacheKey = [NSString stringWithFormat:@"lastSeenRecordID%@%@", senderReference.recordID, [DUser currentUser].recordID];

    NSString *messageCacheKey = [NSString stringWithFormat:@"lastSeen%@%@", senderReference.recordID, [DUser currentUser].recordID];

    [[NSUserDefaults standardUserDefaults] setObject:message forKey:messageCacheKey];
    [[NSUserDefaults standardUserDefaults] setObject:queryNotification.recordID forKey:lastSeenRecordIDCacheKey];
    
    // Update the current user's lastSeen
    NSMutableArray *lastSeens = [NSMutableArray arrayWithArray:[DUser currentUser].lastSeens];
    
    // Only have the record once
    if (![lastSeens containsObject:queryNotification.recordID]) {
      [lastSeens addObject:queryNotification.recordID];
    }
    
    currentUser.lastSeens = lastSeens;
    
    [currentUser saveWithCompletion:nil];

    // Get the push data
    url = [NSURL URLWithString:userInfo[@"url"]];
    
    double latitude = [userInfo[@"lat"] doubleValue];
    double longitude = [userInfo[@"long"] doubleValue];
    
    // Handle notification
    if (application && ![message.senderRecordID isEqual:currentUser.recordID]) {// While in app
      JCNotificationBanner *banner;
      if (url) {
        banner = [[JCNotificationBanner alloc] initWithTitle:message.notificationTitle message:message.notificationMessage tapHandler:^{
          [[UIApplication sharedApplication] openURL:url];
        }];
        
        
      } else if (latitude && longitude) {
        MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude, longitude) addressDictionary:nil];
        mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
        mapItem.name = [NSString stringWithFormat:@"%@'s Location", message.senderFullName];
        
        banner = [[JCNotificationBanner alloc] initWithTitle:message.notificationTitle message:message.notificationMessage tapHandler:^{
          [mapItem openInMapsWithLaunchOptions:nil];
        }];
        
      } else {
        banner = [[JCNotificationBanner alloc] initWithTitle:message.notificationTitle message:message.notificationMessage tapHandler:^{
          // Open PVC of the user
          DUser *user = [[DUser alloc] init];
          user.recordID = [[CKRecordID alloc] initWithRecordName:message.senderRecordID[@"recordName"] zoneID:message.senderRecordID[@"zoneID"]];
          
          user = [user fetchFromCache];
          
          if (!user) {
            [user fetchWithSuccessBlock:^(DUser * _Nullable fetchedUser) {
              dispatch_async(dispatch_get_main_queue(), ^{
                ProfileViewController *pvc = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"ProfileViewControllerOther"];
                pvc.profileUser = fetchedUser;
                
                [self.visibleViewController presentViewController:pvc animated:YES completion:nil];
                
              });
              
            } failureBlock:nil];
            
          } else {
            ProfileViewController *pvc = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"ProfileViewControllerOther"];
            pvc.profileUser = user;
            
            [self.visibleViewController presentViewController:pvc animated:YES completion:nil];
          }
        }];
      }
      
      // Present the notification
      [[JCNotificationBannerPresenterIOS7Style new] presentNotification:banner finished:nil];
      
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
        [[UIApplication sharedApplication] openURL:url];

      } else if (latitude && longitude) {
        MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude, longitude) addressDictionary:nil];
        mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
        mapItem.name = [NSString stringWithFormat:@"%@'s Location", message.senderFullName];
        
        [mapItem openInMapsWithLaunchOptions:nil];
        
      } else {
        // Open PVC of the user
        DUser *user = [[DUser alloc] init];
        user.recordID = [[CKRecordID alloc] initWithRecordName:message.senderRecordID[@"recordName"] zoneID:message.senderRecordID[@"zoneID"]];
        
        user = [user fetchFromCache];
        
        if (!user) {
          [user fetchWithSuccessBlock:^(DUser * _Nullable fetchedUser) {
            dispatch_async(dispatch_get_main_queue(), ^{
              ProfileViewController *pvc = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"ProfileViewControllerOther"];
              pvc.profileUser = fetchedUser;
              
              [self.visibleViewController presentViewController:pvc animated:YES completion:nil];
              
            });
            
          } failureBlock:nil];
          
        } else {
          ProfileViewController *pvc = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"ProfileViewControllerOther"];
          pvc.profileUser = user;
          
          [self.visibleViewController presentViewController:pvc animated:YES completion:nil];
        }
        
      }
    }
    
  } else if (application && notification) {
    JCNotificationBanner *banner = [[JCNotificationBanner alloc] initWithTitle:@"Dude" message:queryNotification.alertBody tapHandler:nil];
    [[JCNotificationBannerPresenterIOS7Style new] presentNotification:banner finished:nil];
    
    [[[CKContainer defaultContainer] publicCloudDatabase] deleteRecordWithID:queryNotification.recordID completionHandler:^(CKRecordID * _Nullable recordID, NSError * _Nullable error) {
      if (error) {
        NSLog(@"Couldn't delete notification record");
      }
    }];
  }
}

- (void)application:(UIApplication*)application handleActionWithIdentifier:(NSString*)identifier forRemoteNotification:(NSDictionary*)userInfo completionHandler:(void (^)())completionHandler {
  CKNotification *notification = [CKNotification notificationFromRemoteNotificationDictionary:userInfo];
  
  if (notification.isPruned) {
    NSLog(@"Notification is pruned use CKFetchNotificationChangesOperation");
  }
  
  CKQueryNotification *querynotification = [CKQueryNotification notificationFromRemoteNotificationDictionary:userInfo];
  
  DMessage *message = [NSKeyedUnarchiver unarchiveObjectWithData:querynotification.recordFields[@"Message"]];
  
  if (message) {
    DUser *user = [[DUser alloc] init];
    user.recordID = [[CKRecordID alloc] initWithRecordName:message.senderRecordID[@"recordName"] zoneID:message.senderRecordID[@"zoneID"]];
    
    user = [user fetchFromCache];
    
    if (!user) {
      [user fetchWithSuccessBlock:^(DUser * _Nullable fetchedUser) {
        dispatch_async(dispatch_get_main_queue(), ^{
          MessagesTableViewController *messagesTableVC = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"MessagesTable"];
          messagesTableVC.selectedUsers = @[fetchedUser];
          
          [self.window.rootViewController.navigationController presentViewController:messagesTableVC animated:YES completion:nil];
          
          completionHandler();
          
        });
        
      } failureBlock:nil];
      
      MessagesTableViewController *messagesTableVC = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"MessagesTable"];
      messagesTableVC.selectedUsers = @[user];
      
      [self.window.rootViewController.navigationController presentViewController:messagesTableVC animated:YES completion:nil];
      
      completionHandler();
    }
  }
}

@end