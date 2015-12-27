//
//  DUserWatch.m
//  Dude
//
//  Created by Georges Kanaan on 29/11/15.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

#import "DUserWatch.h"

// Pods
#import <Parse/PFObject+Subclass.h>

NSString* const ProfileImageKey = @"profileImage";
NSString* const BlockedEmailsKey = @"blockedEmails";
NSString* const ContactsEmailsKey = @"contactsEmails";
NSString* const FavouriteContactsKey = @"favouriteContactsEmails";
NSString* const LastSeensKey = @"lastSeens";
NSString* const FullNameKey = @"fullName";

@implementation DUserWatch

@dynamic profileImage, lastSeens, blockedEmails,  contactsEmails, favouriteContactsEmails, fullName;

#pragma mark - Initializations
+ (instancetype)currentUser {
  DUserWatch *currentUser = (DUserWatch*)[super currentUser];
  
  currentUser.profileImage = (PFFile*)currentUser[ProfileImageKey];
  
  currentUser.blockedEmails = [NSSet setWithArray:currentUser[BlockedEmailsKey]];
  currentUser.contactsEmails = [NSSet setWithArray:currentUser[ContactsEmailsKey]];
  currentUser.favouriteContactsEmails = [NSSet setWithArray:currentUser[FavouriteContactsKey]];
  
  currentUser.fullName = currentUser[FullNameKey];
  
  currentUser.lastSeens = currentUser[LastSeensKey];
    
  return currentUser;
}

+ (instancetype)object {
  DUserWatch *user = (DUserWatch*)[super object];
  
  user.profileImage = (PFFile*)user[ProfileImageKey];
    
  user.blockedEmails = [NSSet setWithArray:user[BlockedEmailsKey]];
  user.contactsEmails = [NSSet setWithArray:user[ContactsEmailsKey]];
  user.favouriteContactsEmails = [NSSet setWithArray:user[FavouriteContactsKey]];
  
  user.fullName = user[FullNameKey];
  
  user.lastSeens = user[LastSeensKey];
  
  return user;
}

#pragma mark - Support NSSet
- (void)setObject:(nonnull id)object forKey:(nonnull NSString*)key {
  if ([object isKindOfClass:[NSSet class]]) {
    NSMutableSet *objectSet = [(NSSet*)object mutableCopy];
    
    // Make sure we don't have our own email in any of the contact arrays
    if (self.email) {// Check that email isn't ni, it wil lcause a crash otherwise
      [objectSet removeObject:self.email];
    }
    
    [super setObject:[objectSet allObjects] forKey:key];
  
  } else {
    [super setObject:object forKey:key];
  }
}

- (id)objectForKey:(nonnull NSString*)key {
  id object = [super objectForKey:key];
  
  if ([object isKindOfClass:[NSSet class]]) {
    NSMutableSet *objectSet = [(NSSet*)object mutableCopy];
    [objectSet removeObject:self.email];
    
    return objectSet;
    
  }
  
  return object;
}

#pragma mark - Other
+ (void)logOut {
  // Create the userunique keys
  NSString *contactsKey = [NSString stringWithFormat:@"contact%@", [DUserWatch currentUser].username];
  
  // Clear the saved contacts for this username
  [[NSUserDefaults standardUserDefaults] setObject:nil forKey:contactsKey];
  
  // Clear twitter & facebook preferences for this device
  [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"twitterAccountID"];
  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"askTwitter"];
  
  [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"facebookAccountID"];
  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"askFacebook"];
  
  // Sync NSUserDefaults
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  [super logOut];
}

@end