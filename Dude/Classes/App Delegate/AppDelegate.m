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
#import "CloudKitManager.h"

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

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken {
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
  [self application:application didReceiveRemoteNotification:userInfo];
  
  completionHandler(UIBackgroundFetchResultNoData);
}

- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo {
  [CloudKitManager fetchCurrentUserWithSuccessBlock:^(CKRecord * _Nullable currentUserRecord) {
    DUser *currentUser = [[DUser alloc] initWithCKRecord:currentUserRecord];
    CKNotification *notification = [CKNotification notificationFromRemoteNotificationDictionary:userInfo];
    
    if (notification.isPruned) {
      NSLog(@"Notification is pruned use CKFetchNotificationChangesOperation");
    }
    
    CKQueryNotification *queryNotification = [CKQueryNotification notificationFromRemoteNotificationDictionary:userInfo];
    
    DMessage *message = [NSKeyedUnarchiver unarchiveObjectWithData:queryNotification.recordFields[@"Message"]];
    
    if (message) {
      // Update the lastSeen cache
      CKReference *senderReference = queryNotification.recordFields[@"Sender"];
      NSString *lastSeenRecordIDCacheKey = [NSString stringWithFormat:@"lastSeenRecordID%@%@", senderReference.recordID, currentUserRecord.recordID];
      
      NSString *messageCacheKey = [NSString stringWithFormat:@"lastSeen%@%@", senderReference.recordID, currentUserRecord.recordID];
      
      [NSUserDefaults.standardUserDefaults setObject:message forKey:messageCacheKey];
      [NSUserDefaults.standardUserDefaults setObject:queryNotification.recordID forKey:lastSeenRecordIDCacheKey];
      
#warning this must be a CKReference
      // Update the current user's lastSeen
      NSMutableArray *lastSeens = [NSMutableArray arrayWithArray:currentUser.lastSeens];
      
      // Only have the record once
      if (![lastSeens containsObject:queryNotification.recordID]) {
        [lastSeens addObject:queryNotification.recordID];
      }
      
      currentUser.userRecord[@"LastSeens"] = lastSeens;
      
      // Save
      [[[CKContainer defaultContainer] publicCloudDatabase] saveRecord:currentUser.userRecord completionHandler:^(CKRecord * _Nullable record, NSError * _Nullable error) {
#warning handle
      }];
      
      // Get the push data
      url = [NSURL URLWithString:userInfo[@"url"]];
      
      double latitude = [userInfo[@"lat"] doubleValue];
      double longitude = [userInfo[@"long"] doubleValue];
      
      // Handle notification
      if (application && ![[NSKeyedUnarchiver unarchiveObjectWithData:message.senderRecordIDData] isEqual:currentUser.recordID]) {// While in app
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
            [CloudKitManager fetchUserWithRecordID:[NSKeyedUnarchiver unarchiveObjectWithData:message.senderRecordIDData] successBlock:^(CKRecord * _Nullable userRecord) {
              ProfileViewController *pvc = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"ProfileViewControllerOther"];
              pvc.profileUser = [[DUser alloc] initWithCKRecord:userRecord];
              
              [self.visibleViewController presentViewController:pvc animated:YES completion:nil];
              
            } failureBlock:^(NSError * _Nullable error) {
#warning handle
            } preferCache:YES];
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
          [CloudKitManager fetchUserWithRecordID:[NSKeyedUnarchiver unarchiveObjectWithData:message.senderRecordIDData] successBlock:^(CKRecord * _Nullable userRecord) {
            ProfileViewController *pvc = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"ProfileViewControllerOther"];
            pvc.profileUser = [[DUser alloc] initWithCKRecord:userRecord];
            
            [self.visibleViewController presentViewController:pvc animated:YES completion:nil];
            
          } failureBlock:^(NSError * _Nullable error) {
#warning handle
          } preferCache:YES];
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
    
  } failureBlock:^(NSError * _Nullable error) {
#warning handle
    
  } preferCache:YES];
  
}

- (void)application:(UIApplication*)application handleActionWithIdentifier:(NSString*)identifier forRemoteNotification:(NSDictionary*)userInfo completionHandler:(void (^)())completionHandler {
  CKNotification *notification = [CKNotification notificationFromRemoteNotificationDictionary:userInfo];
  
  if (notification.isPruned) {
#warning handle
    NSLog(@"Notification is pruned use CKFetchNotificationChangesOperation");
  }
  
  CKQueryNotification *querynotification = [CKQueryNotification notificationFromRemoteNotificationDictionary:userInfo];
  
  DMessage *message = [NSKeyedUnarchiver unarchiveObjectWithData:querynotification.recordFields[@"Message"]];
  
  // Get the sender's user and forward it to the message TVC for reply.
  if (message) {
    [CloudKitManager fetchUserWithRecordID:[NSKeyedUnarchiver unarchiveObjectWithData:message.senderRecordIDData] successBlock:^(CKRecord * _Nullable userRecord) {
      DUser *user = [[DUser alloc] initWithCKRecord:userRecord];
      
      dispatch_async(dispatch_get_main_queue(), ^{
        MessagesTableViewController *messagesTableVC = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"MessagesTable"];
        messagesTableVC.selectedUsers = @[user];
        
        [self.window.rootViewController.navigationController presentViewController:messagesTableVC animated:YES completion:nil];
        
        completionHandler();
      });
      
      
    } failureBlock:^(NSError * _Nullable error) {
#warning handle
    } preferCache:YES];
    
  }
}

@end
