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

+ (instancetype _Nonnull)sharedInstance;

// Adding
- (void)addDeviceContactsAndSendNotification:(BOOL)sendNotification;
- (void)addContactToFavourites:(DUser* _Nonnull)user;
- (void)addContactToContacts:(DUser* _Nonnull)user sendNotification:(BOOL)sendNotification;

// Blocking and unblocking
- (void)blockContact:(DUser* _Nonnull)user;
- (void)unblockContact:(DUser* _Nonnull)user;
- (BOOL)currentUserBlockedContact:(DUser* _Nonnull)user;
- (BOOL)contactBlockedCurrentUser:(DUser* _Nonnull)user;

// Removing
- (NSSet* _Nonnull)removeContact:(DUser* _Nonnull)user reloadContacts:(BOOL)reload;
- (void)removeContactFromFavourites:(DUser* _Nonnull)user;

// Fetching contacts
- (NSSet* _Nonnull)getContactsRefreshedNecessary:(BOOL)needsLatestData favourites:(BOOL)favs;

// Last seens
- (DMessage* _Nullable)latestMessageForContact:(DUser* _Nonnull)user;

// Added notification
- (void)sendAddedNotificationToContact:(DUser* _Nonnull)user;

// Requesting status
- (BOOL)requestStatusForContact:(DUser* _Nonnull)user inBackground:(BOOL)background;

@end
