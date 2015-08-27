//
//  ContactsManager.m
//  Dude
//
//  Created by Georges Kanaan on 3/10/15.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

#import "ContactsManager.h"

// Pods
#import <SDWebImage/SDWebImageManager.h>
#import <APAddressBook/APAddressBook.h>
#import <APAddressBook/APContact.h>

// Managers
#import "MessagesManager.h"

// Classes
#import "AppDelegate.h"

// Controllers
#import "UsersTableViewController.h"

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
- (BOOL)currentUserBlockedContact:(NSString*)email {
  for (NSString *blockedEmail in [DUser currentUser].blockedEmails) {
    if ([blockedEmail isEqualToString:email]) return YES;
  }
  
  return NO;
}

- (BOOL)contactBlockedCurrentUser:(DUser*)user {
  for (NSString *blockedEmail in user.blockedEmails) {
    if ([blockedEmail isEqualToString:[DUser currentUser].email]) return YES;
  }
  
  return NO;
}

- (void)blockContact:(DUser*)user {
  // Verify that this user is not blocked already
  if ([[DUser currentUser].blockedEmails containsObject:user.email]) return;
  
  // Get current users
  NSMutableSet *savedContacts = [[DUser currentUser].blockedEmails mutableCopy];
  
  // Add username
  [savedContacts addObject:user.email];
  
  // Save the blocked users
  [[DUser currentUser] setBlockedEmails:savedContacts];
  [[DUser currentUser] saveEventually];
}

- (void)unblockContact:(DUser*)user {
  // Verify that this user is blocked
  if (![[DUser currentUser].blockedEmails containsObject:user.email]) return;
  
  // Get current users
  NSMutableSet *savedContacts = [[DUser currentUser].blockedEmails mutableCopy];
  
  // Remove username
  [savedContacts removeObject:user.email];
  
  // Save the blocked users
  [[DUser currentUser] setBlockedEmails:savedContacts];
  [[DUser currentUser] saveEventually];
}

#pragma mark - Fetching
- (NSArray*)getContactsRefreshedNecessary:(BOOL)needsLatestData favourites:(BOOL)favs {
  if (needsLatestData) [[DUser currentUser] fetch];
  
  NSSet *emails = (favs) ? [DUser currentUser].favouriteContactsEmails : [DUser currentUser].contactsEmails;
  if (!emails) return @[];
  
  // Get the PFUsers
  PFQuery *userQuery = [DUser query];
  
  [userQuery whereKey:@"email" containedIn:[emails allObjects]];
  if (!needsLatestData) [userQuery fromLocalDatastore];
  
  NSArray *users = [userQuery findObjects];
  
  if (!users && !needsLatestData) {
    return [self getContactsRefreshedNecessary:YES favourites:favs];
  }
  
  if (needsLatestData) [PFObject pinAllInBackground:users withName:WatchRequestContacts];
  
  return users;
}

- (NSString*)lastSeenForContactEmail:(NSString*)email {
  // Check that we didnt block this user and that he didnt block us
  PFQuery *userQuery = [DUser query];
  [userQuery whereKey:@"email" equalTo:email];
  
  DUser *user = (DUser*)[userQuery getFirstObject];
  
  if (!user) return @"Error retrieving last seen.";
  
  BOOL isBlockedByUser = [[DUser currentUser].blockedEmails containsObject:user.email];
  BOOL isUserBlocked = [user.blockedEmails containsObject:[DUser currentUser].email];
  
  if (isBlockedByUser) return @"Blocked.";
  if (isUserBlocked) return @"Last Seen not available.";
  
  // Get the last lastSeen for this user
  NSDictionary *lastSeens = [DUser currentUser].lastSeens;
  NSString *lastSeen = lastSeens[email];
  NSString *timeStamp =  [self lastSeenTimestampForEmail:email];
  
  NSString *finalLastSeenString = @"";
  if (lastSeen && timeStamp) {
    finalLastSeenString = [NSString stringWithFormat:@"%@ %@",lastSeen, timeStamp];
    
  } else if (lastSeen) {
    finalLastSeenString = lastSeen;
  }
  
  return finalLastSeenString;
}

- (NSString*)lastSeenTimestampForEmail:(NSString*)email {
  // Get the users last notification sent to us
  NSDictionary *lastSeens = [DUser currentUser].lastSeens;
  NSData *timestampData = lastSeens[[NSString stringWithFormat:@"%@timestamp", email]];
  
  if (!timestampData) return nil;
  
  NSDate *timestamp = [NSKeyedUnarchiver unarchiveObjectWithData:timestampData];
  
  NSInteger secondsSinceTimeStamp = -[timestamp timeIntervalSinceNow];
  NSString *timestampString;
  
  if (secondsSinceTimeStamp) {
    if (secondsSinceTimeStamp <= 120) {
      timestampString = @"(Now)";
      
    } else if (secondsSinceTimeStamp > 120 && secondsSinceTimeStamp < 3600) {
      NSInteger minutes = secondsSinceTimeStamp/60;
      timestampString = [NSString stringWithFormat:@"(%lim ago)", (long)minutes];
      
    } else if (secondsSinceTimeStamp < 86400) {
      NSInteger hours = secondsSinceTimeStamp/3600;
      timestampString = [NSString stringWithFormat:@"(%lih ago)", (long)hours];
      
    } else {
      NSInteger days = secondsSinceTimeStamp/86400;
      timestampString = [NSString stringWithFormat:@"(%lid ago)", (long)days];
    }
  }
  
  return timestampString;
}

#pragma mark - Adding
- (BOOL)addContactToContacts:(DUser*)user sendNotification:(BOOL)sendNotification {
  NSMutableSet *savedContacts = [[DUser currentUser].contactsEmails mutableCopy];
  if ([user.email.lowercaseString isEqualToString:[DUser currentUser].email.lowercaseString]  || [savedContacts containsObject:user.email.lowercaseString]) return YES;
  
  if (user) {
    // Save the user to the list of contacts
    [savedContacts addObject:user.email];
    
    [[DUser currentUser] setContactsEmails:savedContacts];
    
    // Notify the user that we added him
    if (sendNotification) [self sendAddedNotificationToContact:user];
    
    return [[DUser currentUser] save];
    
  } else {// User with email does not exist
    return NO;
  }
}

- (BOOL)addContactToFavourites:(NSString*)email {
  NSMutableSet *savedContacts = [[DUser currentUser].favouriteContactsEmails mutableCopy];
  if ([email isEqualToString:[DUser currentUser].email]  || [savedContacts containsObject:email.lowercaseString]) return YES;
  
  // Get the user with that email to make sure its valid
  PFQuery *userQuery = [DUser query];
  [userQuery whereKey:@"email" equalTo:email.lowercaseString];
  
  [userQuery fromLocalDatastore];
  
  if ([userQuery getFirstObject]) {
    // Save the user to the list of contacts
    [savedContacts addObject:email];
    
    [[DUser currentUser] setFavouriteContactsEmails:savedContacts];
    
    return [[DUser currentUser] save];
    
  } else {// User with email does not exist
    return NO;
  }
}

- (void)addDeviceContactsAndSendNotification:(BOOL)sendNotification {
  Reachability *reachability = [Reachability reachabilityForInternetConnection];
  if (![reachability isReachableViaWiFi]) return;
  
  APAddressBook *addressBook = [APAddressBook new];
  addressBook.fieldsMask = APContactFieldEmails;
  
  [addressBook loadContactsOnQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0) completion:^(NSArray *contacts, NSError *error) {
    if (!error && contacts.count > 0) {
      NSMutableSet *contactEmails = [NSMutableSet new];
      
      for (APContact *contact in contacts) {
        for (NSString *email in contact.emails) {
          if (![email.lowercaseString isEqualToString:[DUser currentUser].email.lowercaseString]) {
            [contactEmails addObject:email];
          }
        }
      }
      
      PFQuery *userQuery = [DUser query];
      [userQuery whereKey:@"email" containedIn:[contactEmails allObjects]];
      
      NSArray *users = [userQuery findObjects];
      
      NSMutableSet *currentUserContacts = [[DUser currentUser].contactsEmails mutableCopy];
      
      for (DUser *user in users) {
        [currentUserContacts addObject:user.email];
      }
      
      [[DUser currentUser] setContactsEmails:currentUserContacts];
      
      [[DUser currentUser] saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        UIViewController *vc = appDelegate.visibleViewController;
        
        if ([vc isKindOfClass:[UsersTableViewController class]]) {
          UsersTableViewController *userTableVC = (UsersTableViewController*)vc;
          [userTableVC reloadData];
        }
        
        for (DUser *user in users) {
          [self sendAddedNotificationToContact:user];
        }
        
      }];
    }
  }];
}

#pragma mark - Removing
- (NSArray*)removeContact:(NSString*)email reloadContacts:(BOOL)reload {
  // Remove the username from the list
  NSMutableSet *savedContacts = [[DUser currentUser].contactsEmails mutableCopy];
  
  [savedContacts removeObject:email];
  
  [[DUser currentUser] setContactsEmails:savedContacts];
  [[DUser currentUser] saveEventually];
  
  // Reload contacts if necessary
  return (reload) ? [self getContactsRefreshedNecessary:YES favourites:NO] : nil;
}

- (NSArray*)removeContactFromFavourites:(NSString*)email reloadFavouriteContacts:(BOOL)reload {
  // Remove the username from the list
  NSMutableSet *savedContacts = [[DUser currentUser].favouriteContactsEmails mutableCopy];
  [savedContacts removeObject:email];
  
  [[DUser currentUser] setFavouriteContactsEmails:savedContacts];
  [[DUser currentUser] saveEventually];
  
  // Reload contacts if necessary
  return (reload) ? [self getContactsRefreshedNecessary:YES favourites:NO] : nil;
}

#pragma mark Added Notification
- (void)sendAddedNotificationToContact:(DUser*)user {
  if (!user) return;
    
  // Make sure we are allowed send the notification
  BOOL isBlocked = [user.blockedEmails containsObject:[DUser currentUser].email];
  BOOL didBlocked = [[DUser currentUser].blockedEmails containsObject:user.email];
  BOOL isAddedByUser = [user.contactsEmails containsObject:[DUser currentUser].email.lowercaseString];
  
  if (isAddedByUser || isBlocked || didBlocked) return;
  
  // Build the actual push notification target query
  PFQuery *query = [PFInstallation query];
  [query whereKey:@"user" equalTo:user];
  
  // Send the notification.
  PFPush *push = [PFPush push];
  [push setMessage:[NSString stringWithFormat:@"Duderino, %@ just added you. Why not add them back?", [DUser currentUser].username]];
  [push setQuery:query];
  
  [push sendPushInBackground];
}

#pragma mark - Requesting Status Notification
- (void)requestStatusForContact:(DUser*)user inBackground:(BOOL)background {
  if (!user.email) return;
  
  // Make sure we are allowed request the status
  BOOL isBlocked = [user.blockedEmails containsObject:[DUser currentUser].email];
  BOOL didBlocked = [[DUser currentUser].blockedEmails containsObject:user.email];
  
  if (isBlocked || didBlocked) return;
  
  // Build the actual push notification target query
  PFQuery *query = [PFInstallation query];
  [query whereKey:@"user" equalTo:user];
  
  // Send the notification.
  PFPush *push = [PFPush push];
  [push setMessage:[NSString stringWithFormat:@"Duderino, %@ would like to know what you're up to.", [DUser currentUser].username]];
  [push setQuery:query];
  
  if (background)
    [push sendPushInBackground];
  else
    [push sendPush:nil];
}

@end