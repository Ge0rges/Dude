//
//  ContactsManager.h
//  Dude
//
//  Created by Georges Kanaan on 3/10/15.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

// Frameworks
#import <Foundation/Foundation.h>
#import <Reachability/Reachability.h>
#import <AddressBook/AddressBook.h>

// Constants
#import "Constants.h"

@interface ContactsManager : NSObject

+ (instancetype)sharedInstance;

// Adding
- (void)addDeviceContactsAndSendNotification:(BOOL)sendNotification;
- (BOOL)addContactToFavourites:(DUser*)user;
- (BOOL)addContactToContacts:(DUser*)user sendNotification:(BOOL)sendNotification;

// Blocking and unblocking
- (void)blockContact:(DUser*)user;
- (void)unblockContact:(DUser*)user;
- (BOOL)currentUserBlockedContact:(DUser*)user;
- (BOOL)contactBlockedCurrentUser:(DUser*)user;

// Removing
- (NSArray*)removeContact:(DUser*)user reloadContacts:(BOOL)reload;
- (NSArray*)removeContactFromFavourites:(DUser*)user reloadFavouriteContacts:(BOOL)reload;

// Fetching contacts
- (NSArray*)getContactsRefreshedNecessary:(BOOL)needsLatestData favourites:(BOOL)favs;

// Last seens
- (NSString*)lastSeenForContactEmail:(NSString*)email;

// Added notification
- (void)sendAddedNotificationToContact:(DUser*)user;

// Requesting status
- (void)requestStatusForContact:(DUser*)user inBackground:(BOOL)background;

@end
