//
//  ContactsManager.h
//  Dude
//
//  Created by Georges Kanaan on 3/10/15.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

// Frameworks
#import <Foundation/Foundation.h>
#import "Reachability.h"
#import <Contacts/Contacts.h>

// Constants
#import "Constants.h"

// Models
#import "DMessage.h"
#import "DUser.h"

@interface ContactsManager : NSObject

+ (instancetype)sharedInstance;

// Adding
- (void)addDeviceContactsAndSendNotification:(BOOL)sendNotification;
- (void)addContactToFavourites:(DUser*)user;
- (void)addContactToContacts:(DUser*)user sendNotification:(BOOL)sendNotification;

// Blocking and unblocking
- (void)blockContact:(DUser*)user;
- (void)unblockContact:(DUser*)user;
- (BOOL)currentUserBlockedContact:(DUser*)user;
- (BOOL)contactBlockedCurrentUser:(DUser*)user;

// Removing
- (NSArray*)removeContact:(DUser*)user reloadContacts:(BOOL)reload;
- (void)removeContactFromFavourites:(DUser*)user;

// Fetching contacts
- (NSArray*)getContactsRefreshedNecessary:(BOOL)needsLatestData favourites:(BOOL)favs;

// Last seens
- (DMessage*)latestMessageForContact:(DUser*)user;

// Added notification
- (void)sendAddedNotificationToContact:(DUser*)user;

// Requesting status
- (void)requestStatusForContact:(DUser*)user inBackground:(BOOL)background;

@end
