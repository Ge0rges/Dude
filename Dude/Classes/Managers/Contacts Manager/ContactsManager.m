//
//  ContactsManager.m
//  Dude
//
//  Created by Georges Kanaan on 3/10/15.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

#import "ContactsManager.h"

// Frameworks
#import <Social/Social.h>
#import <Contacts/Contacts.h>
#import <UIKit/UIKit.h>

// Constants
#import "Constants.h"

// Pods
#import <SDWebImage/SDWebImageManager.h>
#import <SOMotionDetector/SOMotionDetector.h>

// Managers
#import "MessagesManager.h"
#import "WatchConnectivityManager.h"

// Classes
#import "AppDelegate.h"

// Controllers
#import "UsersTableViewController.h"

// Models
#import "DUserWatch.h"

@interface ContactsManager ()

@end

@implementation ContactsManager

+ (instancetype)sharedInstance {
  
  static ContactsManager *sharedContactsManager = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedContactsManager = [self new];
  });
  
  return sharedContactsManager;
}

#pragma mark - Blocking
- (BOOL)currentUserBlockedContact:(DUser*)user {
  DUser *currentUser = [DUser currentUser];

  for (CKRecordID *blockedRecordID in currentUser.blockedContacts) {
    if ([blockedRecordID isEqual:user.recordID]) return YES;
  }
  
  return NO;
}

- (BOOL)contactBlockedCurrentUser:(DUser*)user {
  DUser *currentUser = [DUser currentUser];

  for (CKRecordID *blockedRecordID in user.blockedContacts) {
    if ([blockedRecordID isEqual:currentUser.recordID]) return YES;
  }
  
  return NO;
}

- (void)blockContact:(DUser*)user {
  DUser *currentUser = [DUser currentUser];

  // Verify that this user is not blocked already
  if ([currentUser.blockedContacts containsObject:user.recordID]) return;
  
  // Get current users
  NSMutableSet *savedContacts = [currentUser.blockedContacts mutableCopy];
  
  // Add username
  [savedContacts addObject:user.recordID];
  
  // Save the blocked users
  [currentUser setBlockedContacts:savedContacts];
  [currentUser saveWithCompletion:nil];
}

- (void)unblockContact:(DUser*)user {
  DUser *currentUser = [DUser currentUser];

  // Verify that this user is blocked
  if (![currentUser.blockedContacts containsObject:user.recordID]) return;
  
  // Get current users  s
  NSMutableSet *savedContacts = [currentUser.blockedContacts mutableCopy];
  
  // Remove username
  [savedContacts removeObject:user.recordID];
  
  // Save the blocked users
  [currentUser setBlockedContacts:savedContacts];
  [currentUser saveWithCompletion:nil];
}

#pragma mark - Fetching
- (void)fetchContactsFromCache:(BOOL)fromCache favorites:(BOOL)favorites successBlock:(void(^_Nullable)(NSArray <CKRecord *> * _Nullable fetchedUsers))successBlock failureBlock:(void(^_Nullable)(NSError * _Nullable error))failureBlock {
  DUser *currentUser = [DUser currentUser];
  
  if (fromCache) {
    NSArray *users = [[self contactsFromCacheFavorites:favorites] allObjects];
    
    if (users.count > 0) {
      successBlock(users);
    
    } else {
      failureBlock([NSError errorWithDomain:@"Empty Cache" code:1 userInfo:nil]);
    }
    
  } else {
    CKQuery *query = [[CKQuery alloc] initWithRecordType:@"Users" predicate:[NSPredicate predicateWithFormat:@"creatorUserRecordID = %@" argumentArray:[currentUser.contacts allObjects]]];
    [[[CKContainer defaultContainer] publicCloudDatabase] performQuery:query inZoneWithID:nil completionHandler:^(NSArray *results, NSError *error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        if (error) {
          failureBlock(error);
          
        } else if ([results count] > 0) {
          successBlock(results);
        }
      });
      
      if ([results count] > 0) {
        NSMutableSet *watchUsers = [NSMutableSet new];
        NSMutableArray *filteredResults = (favorites) ? [NSMutableArray new] : [results copy];
        
        for (CKRecord *userRecord in results) {
          
          // Update the cache
          [[NSUserDefaults standardUserDefaults] setObject:userRecord forKey:[NSString stringWithFormat:@"%@", userRecord.recordID]];
          [[NSUserDefaults standardUserDefaults] synchronize];
          
          // Check if favorite
          if ([currentUser.favouriteContacts containsObject:userRecord.recordID]) {
            if (favorites) {// If we should be filtering for favorites
              [filteredResults addObject:userRecord];
            }
            
            // Add to watch users
            if ([WatchConnectivityManager sharedManager]) {
              DUser *user = [DUser userWithRecord:userRecord];
              
              DUserWatch *watchUser = [DUserWatch new];
              watchUser.profileImage = [UIImage  imageWithData:user.profileImage];
              watchUser.fullName = [NSString stringWithFormat:@"%@ %@", user.firstName, user.lastName];
              watchUser.recordIDData = [NSKeyedArchiver archivedDataWithRootObject:user.recordID];
              
              [watchUsers addObject:watchUser];
            }
          }
        }
        
        if (filteredResults.count > 0) {
          successBlock(filteredResults);
          
          [[WatchConnectivityManager sharedManager] activateSession];
          
          NSError *error;
          [[WatchConnectivityManager sharedManager].session updateApplicationContext:@{WatchContactsKey: [watchUsers allObjects]} error:&error];
          
        } else {
          failureBlock([NSError errorWithDomain:@"No Contacts found after filtering" code:1 userInfo:nil]);
        }
        
        if (error) {
          NSLog(@"Application context failed with error: %@", error);
        }
      }
    }];
  }
}

- (NSSet <CKRecord *> * _Nullable)contactsFromCacheFavorites:(BOOL)favorites {
  DUser *currentUser = [DUser currentUser];

  NSMutableArray *users = [NSMutableArray new];
  for (CKRecordID *userID in (favorites) ? currentUser.favouriteContacts : currentUser.contacts) {
    // Get the user from the cache the cache
    [users addObject:[[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@", userID]]];
  }
  
  return [NSSet setWithArray:users];

}

- (DMessage*)latestMessageForContact:(DUser*)user {
  DUser *currentUser = [DUser currentUser];

  __block DMessage *message = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"lastSeen%@%@", currentUser.recordID, user.recordID]];
  if (message) {
    return message;
  }
  
  // Cycle through the lastSeens
  [currentUser.lastSeens enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    if ([obj isKindOfClass:[CKReference class]]) {// Avoid crashes. A lastSeen is: @[email, NSData<DMessage>]
      CKReference *reference = (CKReference*)obj;
      
      if ([reference.recordID.recordName isEqualToString:[NSString stringWithFormat:@"%@%@", currentUser.recordID, user.recordID]]) {// If the reference's record ID is equal to a prebuilt ID format
        stop = (BOOL *)YES;// Stop the loop - Wtf apple
        
        [[[CKContainer defaultContainer] publicCloudDatabase] fetchRecordWithID:reference.recordID completionHandler:^(CKRecord * _Nullable record, NSError * _Nullable error) {
          message = (DMessage*)[NSKeyedUnarchiver unarchiveObjectWithData:record[@"Message"]];// Unarchive the NSData into DMessage
          [[NSUserDefaults standardUserDefaults] setObject:message forKey:[NSString stringWithFormat:@"lastSeen%@%@", currentUser.recordID, user.recordID]];
        }];
      }
    }
  }];
  
  return message;
}

#pragma mark - Adding
- (void)addContactToContacts:(DUser*)user sendNotification:(BOOL)sendNotification {
  DUser *currentUser = [DUser currentUser];

  NSMutableSet *savedContacts = [currentUser.contacts mutableCopy];
  if ([user.recordID isEqual:currentUser.recordID]  || [savedContacts containsObject:user.recordID]) return;
  
  if (user) {
    // Save the user to the list of contacts
    [savedContacts addObject:user.recordID];
    
    currentUser.contacts = savedContacts;
    
    // Notify the user that we added him
    if (sendNotification) [self sendAddedNotificationToContact:user];
    
    [currentUser saveWithCompletion:nil];
  }
}

- (void)addContactToFavourites:(DUser*)user {
  if (!user) return;
  
  DUser *currentUser = [DUser currentUser];

  NSMutableSet *savedContacts = [currentUser.favouriteContacts mutableCopy];
  if ([user.recordID isEqual:currentUser.recordID]  || [savedContacts containsObject:user.recordID]) return;
  
  // Save the user to the list of contacts
  [savedContacts addObject:user.recordID];
  
  currentUser.favouriteContacts = savedContacts;
  
  [currentUser saveWithCompletion:^(CKRecord * _Nullable record, NSError * _Nullable error) {
    [self fetchContactsFromCache:NO favorites:YES successBlock:nil failureBlock:nil];
  }];
}

- (void)addDeviceContactsAndSendNotification:(BOOL)sendNotification {
  Reachability *reachability = [Reachability reachabilityForInternetConnection];
  if ([reachability currentReachabilityStatus] != ReachableViaWiFi) return;
    
  [[CKContainer defaultContainer] discoverAllContactUserInfosWithCompletionHandler:^(NSArray<CKDiscoveredUserInfo *> * _Nullable userInfos, NSError * _Nullable error) {
    DUser *currentUser = [DUser currentUser];
    NSMutableSet *currentUserContacts = [currentUser.contacts mutableCopy];
    
    if (userInfos.count > 0) {
      for (CKDiscoveredUserInfo *userInfo in userInfos) {
        [currentUserContacts addObject:userInfo.userRecordID];
        
        [[[CKContainer defaultContainer] publicCloudDatabase] fetchRecordWithID:userInfo.userRecordID completionHandler:^(CKRecord * _Nullable record, NSError * _Nullable error) {
          [self sendAddedNotificationToContact:[DUser userWithRecord:record]];
          
        }];
      }
      
      [currentUser setContacts:currentUserContacts];
      [currentUser saveWithCompletion:^(CKRecord * _Nullable record, NSError * _Nullable error) {
        AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        UIViewController *viewController = appDelegate.visibleViewController;
        
        if ([viewController isKindOfClass:[UsersTableViewController class]] && !error) {
          UsersTableViewController *userTableVC = (UsersTableViewController*)viewController;
          [userTableVC reloadData:nil];
        }
      }];
    }
  }];
}

#pragma mark - Removing
- (void)removeContact:(NSString*)email reloadContacts:(BOOL)reload {
  DUser *currentUser = [DUser currentUser];

  // Remove the username from the list
  NSMutableSet *savedContacts = [currentUser.contacts mutableCopy];
  
  [savedContacts removeObject:email.lowercaseString];
  
  currentUser.contacts = savedContacts;
  [currentUser saveWithCompletion:^(CKRecord * _Nullable record, NSError * _Nullable error) {
    // Reload contacts if necessary
    if (reload) {
      [self fetchContactsFromCache:NO favorites:NO successBlock:nil failureBlock:nil];
    }
  }];
}

- (void)removeContactFromFavourites:(DUser*)user {
  if (!user) return;
  
  DUser *currentUser = [DUser currentUser];

  // Remove the username from the list
  NSMutableSet *savedContacts = [currentUser.favouriteContacts mutableCopy];
  [savedContacts removeObject:user.recordID];
  
  currentUser.favouriteContacts = savedContacts;
  
  [currentUser saveWithCompletion:^(CKRecord * _Nullable record, NSError * _Nullable error) {
    [self fetchContactsFromCache:NO favorites:YES successBlock:nil failureBlock:nil];
  }];
}

#pragma mark Added Notification
- (void)sendAddedNotificationToContact:(DUser*)user {
  if (!user) return;
  
  DUser *currentUser = [DUser currentUser];

  // Make sure we are allowed send the notification
  BOOL isBlocked = [user.blockedContacts containsObject:currentUser.recordID];
  BOOL didBlocked = [currentUser.blockedContacts containsObject:user.recordID];
  BOOL isAddedByUser = [user.contacts containsObject:currentUser.recordID];
  
  if (isAddedByUser || isBlocked || didBlocked) return;

#warning make sure the records get deleted eventually
  // Build the notification record
  CKRecord *notificationRecord = [[CKRecord alloc] initWithRecordType:@"Notification"];
  notificationRecord[@"Message"] = [NSString stringWithFormat:@"Duderino, %@ just added you. Why not add them back?", currentUser.firstName];
  notificationRecord[@"Receiver"] = [NSString stringWithFormat:@"%@", user.recordID];
  notificationRecord[@"Developer"] = @NO;

  // Send the notification.
  [[[CKContainer defaultContainer] publicCloudDatabase] saveRecord:notificationRecord completionHandler:^(CKRecord * _Nullable record, NSError * _Nullable error) {
    if (error) {
      NSLog(@"Error sending added notification");
    }
  }];
}

#pragma mark - Requesting Status Notification
- (BOOL)requestStatusForContact:(DUser*)user {
  DUser *currentUser = [DUser currentUser];

  NSString *key = [NSString stringWithFormat:@"lastStatusRequest%@", user.recordID];
  
  NSDate *lastRequestDate = [[NSUserDefaults standardUserDefaults] objectForKey:key];
  
  if (!user.recordID || (-[lastRequestDate timeIntervalSinceNow] <= 600 && lastRequestDate)) return NO;
  
  // Set time for status request
  [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:key];
  
  // Make sure we are allowed request the status
  BOOL isBlocked = [user.blockedContacts containsObject:currentUser.recordID];
  BOOL didBlocked = [currentUser.blockedContacts containsObject:user.recordID];
  
  if (isBlocked || didBlocked) return NO;
  
  // Build the notification record
  CKRecord *notificationRecord = [[CKRecord alloc] initWithRecordType:@"Notification"];
  notificationRecord[@"Message"] = [NSString stringWithFormat:@"Duderino, %@ would like to know what you're up to.", currentUser.firstName];
  notificationRecord[@"Receiver"] = [NSString stringWithFormat:@"%@", user.recordID];
  notificationRecord[@"Developer"] = @NO;

  // Send the notification.
  [[[CKContainer defaultContainer] publicCloudDatabase] saveRecord:notificationRecord completionHandler:^(CKRecord * _Nullable record, NSError * _Nullable error) {
    if (error) {
      NSLog(@"Error sending added notification");
    }
  }];
  
  return YES;
}

@end