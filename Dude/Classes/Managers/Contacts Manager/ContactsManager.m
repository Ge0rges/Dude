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

  for (NSString *blockedEmail in currentUser.blockedEmails) {
    if ([blockedEmail.lowercaseString isEqualToString:user.email.lowercaseString]) return YES;
  }
  
  return NO;
}

- (BOOL)contactBlockedCurrentUser:(DUser*)user {
  DUser *currentUser = [DUser currentUser];

  for (NSString *blockedEmail in user.blockedEmails) {
    if ([blockedEmail.lowercaseString isEqualToString:currentUser.email.lowercaseString]) return YES;
  }
  
  return NO;
}

- (void)blockContact:(DUser*)user {
  DUser *currentUser = [DUser currentUser];

  // Verify that this user is not blocked already
  if ([currentUser.blockedEmails containsObject:user.email]) return;
  
  // Get current users
  NSMutableSet *savedContacts = [currentUser.blockedEmails mutableCopy];
  
  // Add username
  [savedContacts addObject:user.email];
  
  // Save the blocked users
  [currentUser setBlockedEmails:savedContacts];
  [currentUser saveEventually];
}

- (void)unblockContact:(DUser*)user {
  DUser *currentUser = [DUser currentUser];

  // Verify that this user is blocked
  if (![currentUser.blockedEmails containsObject:user.email]) return;
  
  // Get current users
  NSMutableSet *savedContacts = [currentUser.blockedEmails mutableCopy];
  
  // Remove username
  [savedContacts removeObject:user.email];
  
  // Save the blocked users
  [currentUser setBlockedEmails:savedContacts];
  [currentUser saveEventually];
}

#pragma mark - Fetching
- (NSSet*)getContactsRefreshedNecessary:(BOOL)needsLatestData favourites:(BOOL)favs {
  if (needsLatestData) [[DUser currentUser] fetchIfNeeded];
  
  DUser *currentUser = [DUser currentUser];

  NSSet *emails = (favs) ? currentUser.favouriteContactsEmails : currentUser.contactsEmails;
  if (!emails) return [NSSet new];
  
  // Get the PFUsers
  PFQuery *userQuery = [DUser query];
  
  [userQuery whereKey:@"email" containedIn:[emails allObjects]];

  if (!needsLatestData) {
    [userQuery fromLocalDatastore];
  }
  
  NSSet *users = [NSSet setWithArray:[userQuery findObjects]];
  
  if (needsLatestData) {
    [DUser pinAllInBackground:[users allObjects]];
  }
  
  if (needsLatestData && favs && [WatchConnectivityManager sharedManager]) {
    NSMutableSet *watchUsers = [NSMutableSet new];
    
    for (DUser *user in users) {
      [watchUsers addObject:[NSKeyedArchiver archivedDataWithRootObject:[user watchUser]]];
    }
    
    NSError *error;
    [[WatchConnectivityManager sharedManager].session updateApplicationContext:@{WatchContactsKey: [watchUsers allObjects]} error:&error];
    
    if (error) {
      NSLog(@"Application context failed with error: %@", error);
    }
  }

  return (users) ?: [NSSet new];
}

- (DMessage*)latestMessageForContact:(DUser*)user {
  DUser *currentUser = [DUser currentUser];
  
  // Not necessary to update the user more then once every ten second
  if (-[currentUser.updatedAt timeIntervalSinceNow] > 60.0) {
    currentUser = [currentUser fetch:nil];
  }

  
  __block DMessage *message = nil;// So we can return the message
  
  // Cycle through the lastSeens
  [currentUser.lastSeens enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    if ([obj isKindOfClass:[NSArray class]]) {// Avoid crashes. A lastSeen is: @[email, NSData<DMessage>]
      NSArray *lastSeenArray = (NSArray *)obj;
      
      if ([lastSeenArray[0] isEqualToString:user.email]) {// If the email is equal to the email of the user we're looking for
        stop = (BOOL *)YES;// Stop the loop - Wtf apple
        message = (DMessage*)[NSKeyedUnarchiver unarchiveObjectWithData:lastSeenArray[1]];// Unarchive the NSData into DMessage
      }
    }
  }];
  
  return message;
}

#pragma mark - Adding
- (void)addContactToContacts:(DUser*)user sendNotification:(BOOL)sendNotification {
  DUser *currentUser = [DUser currentUser];

  NSMutableSet *savedContacts = [currentUser.contactsEmails mutableCopy];
  if ([user.email.lowercaseString isEqualToString:currentUser.email.lowercaseString]  || [savedContacts containsObject:user.email.lowercaseString]) return;
  
  if (user) {
    // Save the user to the list of contacts
    [savedContacts addObject:user.email];
    
    [currentUser setContactsEmails:savedContacts];
    
    // Notify the user that we added him
    if (sendNotification) [self sendAddedNotificationToContact:user];
    
    [currentUser saveEventually];
  }
}

- (void)addContactToFavourites:(DUser*)user {
  if (!user) return;
  
  DUser *currentUser = [DUser currentUser];

  NSMutableSet *savedContacts = [currentUser.favouriteContactsEmails mutableCopy];
  if ([user.email.lowercaseString isEqualToString:currentUser.email.lowercaseString]  || [savedContacts containsObject:user.email.lowercaseString]) return;
  
  // Save the user to the list of contacts
  [savedContacts addObject:user.email.lowercaseString];
  
  [currentUser setFavouriteContactsEmails:savedContacts];
  
  [currentUser saveEventually];
  
  [self getContactsRefreshedNecessary:YES favourites:YES];
}

- (void)addDeviceContactsAndSendNotification:(BOOL)sendNotification {
  DUser *currentUser = [DUser currentUser];

  Reachability *reachability = [Reachability reachabilityForInternetConnection];
  if ([reachability currentReachabilityStatus] != ReachableViaWiFi) return;
  
  CNContactStore *contactStore = [CNContactStore new];
  
  [contactStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error){}];

  [contactStore enumerateContactsWithFetchRequest:[[CNContactFetchRequest alloc] initWithKeysToFetch:@[CNContactEmailAddressesKey]] error:nil usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
    NSMutableSet *contactEmails = [NSMutableSet new];
    
    for (CNLabeledValue *emailLabeledValue in contact.emailAddresses) {
      NSString *email = emailLabeledValue.value;
      if (![email.lowercaseString isEqualToString:currentUser.email.lowercaseString]) {
        [contactEmails addObject:email];
      }
    }
    
    PFQuery *userQuery = [DUser query];
    [userQuery whereKey:@"email" containedIn:[contactEmails allObjects]];
    [userQuery whereKey:@"email" notContainedIn:[currentUser.contactsEmails allObjects]];

    [userQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
      NSMutableSet *currentUserContacts = [currentUser.contactsEmails mutableCopy];
      
      for (DUser *user in objects) {
        [currentUserContacts addObject:user.email];
      }
      
      if (objects.count > 0) {
        [currentUser setContactsEmails:currentUserContacts];
        
        [currentUser saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
          AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
          UIViewController *viewController = appDelegate.visibleViewController;
          
          if ([viewController isKindOfClass:[UsersTableViewController class]] && success) {
            UsersTableViewController *userTableVC = (UsersTableViewController*)viewController;
            [userTableVC reloadData:nil];
          }
          
          for (DUser *user in objects) {
            [self sendAddedNotificationToContact:user];
          }
        }];
      }
      
    }];
  }];
}

#pragma mark - Removing
- (NSSet*)removeContact:(NSString*)email reloadContacts:(BOOL)reload {
  DUser *currentUser = [DUser currentUser];

  // Remove the username from the list
  NSMutableSet *savedContacts = [currentUser.contactsEmails mutableCopy];
  
  [savedContacts removeObject:email.lowercaseString];
  
  [currentUser setContactsEmails:savedContacts];
  [currentUser saveEventually];
  
  // Reload contacts if necessary
  return (reload) ? [self getContactsRefreshedNecessary:YES favourites:NO] : nil;
}

- (void)removeContactFromFavourites:(DUser*)user {
  if (!user) return;
  
  DUser *currentUser = [DUser currentUser];

  // Remove the username from the list
  NSMutableSet *savedContacts = [currentUser.favouriteContactsEmails mutableCopy];
  [savedContacts removeObject:user.email];
  
  [currentUser setFavouriteContactsEmails:savedContacts];
  
  [currentUser saveEventually];
  
  [self getContactsRefreshedNecessary:YES favourites:YES];
}

#pragma mark Added Notification
- (void)sendAddedNotificationToContact:(DUser*)user {
  if (!user) return;
  
  DUser *currentUser = [DUser currentUser];

  // Make sure we are allowed send the notification
  BOOL isBlocked = [user.blockedEmails containsObject:currentUser.email];
  BOOL didBlocked = [currentUser.blockedEmails containsObject:user.email];
  BOOL isAddedByUser = [user.contactsEmails containsObject:currentUser.email.lowercaseString];
  
  if (isAddedByUser || isBlocked || didBlocked) return;
  
  // Build the actual push notification target query
  PFQuery *pushQuery = [PFInstallation query];
  [pushQuery whereKey:@"user" equalTo:user];
  
  // Send the notification.
  [PFPush sendPushMessageToQueryInBackground:pushQuery withMessage:[NSString stringWithFormat:@"Duderino, %@ just added you. Why not add them back?", currentUser.username]];
}

#pragma mark - Requesting Status Notification
- (BOOL)requestStatusForContact:(DUser*)user inBackground:(BOOL)background {
  DUser *currentUser = [DUser currentUser];

  NSString *key = [NSString stringWithFormat:@"lastStatusRequest%@", currentUser.email];
  
  NSDate *lastRequestDate = [[NSUserDefaults standardUserDefaults] objectForKey:key];
  
  if (!user.email || (-[lastRequestDate timeIntervalSinceNow] <= 600 && lastRequestDate)) return NO;
  
  // Set time for status request
  [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:key];
  
  // Make sure we are allowed request the status
  BOOL isBlocked = [user.blockedEmails containsObject:currentUser.email];
  BOOL didBlocked = [currentUser.blockedEmails containsObject:user.email];
  
  if (isBlocked || didBlocked) return NO;
  
  // Build the actual push notification target query
  PFQuery *pushQuery = [PFInstallation query];
  [pushQuery whereKey:@"user" equalTo:user];
  
  // Send the notification.  
  if (background) {
    [PFPush sendPushMessageToQueryInBackground:pushQuery withMessage:[NSString stringWithFormat:@"Duderino, %@ would like to know what you're up to.", currentUser.username]];
    return YES;

  } else {
    return [PFPush sendPushMessageToQuery:pushQuery withMessage:[NSString stringWithFormat:@"Duderino, %@ would like to know what you're up to.", currentUser.username] error:nil];
  }
}

@end