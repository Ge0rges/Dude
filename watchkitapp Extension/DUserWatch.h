//
//  DUserWatch.h
//  Dude
//
//  Created by Georges Kanaan on 29/11/15.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

// Pods
#import <Parse/Parse.h>

@interface DUserWatch : PFUser <PFSubclassing>

@property (strong, nonatomic) PFFile *profileImage;

@property (strong, nonatomic) NSString *fullName;

// Set of user emails
@property (strong, nonatomic) NSSet *blockedEmails;
@property (strong, nonatomic) NSSet *contactsEmails;
@property (strong, nonatomic) NSSet *favouriteContactsEmails;

@property (strong, nonatomic) NSDictionary *lastSeens;

+ (instancetype)currentUser;
+ (instancetype)object;

@end