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
- (BOOL)currentUserBlockedContact:(DUser*)user {
  for (NSString *blockedEmail in [DUser currentUser].blockedEmails) {
    if ([blockedEmail.lowercaseString isEqualToString:user.email.lowercaseString]) return YES;
  }
  
  return NO;
}

- (BOOL)contactBlockedCurrentUser:(DUser*)user {
  for (NSString *blockedEmail in user.blockedEmails) {
    if ([blockedEmail.lowercaseString isEqualToString:[DUser currentUser].email.lowercaseString]) return YES;
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

- (DMessage*)lastMessageForContact:(DUser*)user {
  return [DUser currentUser].lastSeens[user.email];
}

#pragma mark - Adding
- (void)addContactToContacts:(DUser*)user sendNotification:(BOOL)sendNotification {
  NSMutableSet *savedContacts = [[DUser currentUser].contactsEmails mutableCopy];
  if ([user.email.lowercaseString isEqualToString:[DUser currentUser].email.lowercaseString]  || [savedContacts containsObject:user.email.lowercaseString]) return;
  
  if (user) {
    // Save the user to the list of contacts
    [savedContacts addObject:user.email];
    
    [[DUser currentUser] setContactsEmails:savedContacts];
    
    // Notify the user that we added him
    if (sendNotification) [self sendAddedNotificationToContact:user];
    
    [[DUser currentUser] saveEventually];
  }
}

- (void)addContactToFavourites:(DUser*)user {
  if (!user) return;

  NSMutableSet *savedContacts = [[DUser currentUser].favouriteContactsEmails mutableCopy];
  if ([user.email.lowercaseString isEqualToString:[DUser currentUser].email.lowercaseString]  || [savedContacts containsObject:user.email.lowercaseString]) return;
  
  // Save the user to the list of contacts
  [savedContacts addObject:user.email.lowercaseString];
  
  [[DUser currentUser] setFavouriteContactsEmails:savedContacts];
  
  [[DUser currentUser] saveInBackground];
}

- (void)addDeviceContactsAndSendNotification:(BOOL)sendNotification {
  Reachability *reachability = [Reachability reachabilityForInternetConnection];
  if ([reachability currentReachabilityStatus] != ReachableViaWiFi) return;
  
  CNContactStore *contactStore = [CNContactStore new];
  
  [contactStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error){}];

  [contactStore enumerateContactsWithFetchRequest:[[CNContactFetchRequest alloc] initWithKeysToFetch:@[CNContactEmailAddressesKey]] error:nil usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
    NSMutableSet *contactEmails = [NSMutableSet new];
    
    for (CNLabeledValue *emailLabeledValue in contact.emailAddresses) {
      NSString *email = emailLabeledValue.value;
      if (![email.lowercaseString isEqualToString:[DUser currentUser].email.lowercaseString]) {
        [contactEmails addObject:email];
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
      AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
      UIViewController *viewController = appDelegate.visibleViewController;
      
      if ([viewController isKindOfClass:[UsersTableViewController class]]) {
        UsersTableViewController *userTableVC = (UsersTableViewController*)viewController;
        [userTableVC reloadData:nil];
      }
      
      for (DUser *user in users) {
        [self sendAddedNotificationToContact:user];
      }
      
    }];
  }];
}

#pragma mark - Removing
- (NSArray*)removeContact:(NSString*)email reloadContacts:(BOOL)reload {
  // Remove the username from the list
  NSMutableSet *savedContacts = [[DUser currentUser].contactsEmails mutableCopy];
  
  [savedContacts removeObject:email.lowercaseString];
  
  [[DUser currentUser] setContactsEmails:savedContacts];
  [[DUser currentUser] saveEventually];
  
  // Reload contacts if necessary
  return (reload) ? [self getContactsRefreshedNecessary:YES favourites:NO] : nil;
}

- (void)removeContactFromFavourites:(DUser*)user {
  if (!user) return;
    
  // Remove the username from the list
  NSMutableSet *savedContacts = [[DUser currentUser].favouriteContactsEmails mutableCopy];
  [savedContacts removeObject:user.email];
  
  [[DUser currentUser] setFavouriteContactsEmails:savedContacts];
  
  [[DUser currentUser] saveInBackground];
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