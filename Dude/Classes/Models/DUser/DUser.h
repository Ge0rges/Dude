//
//  DUser.h
//  Dude
//
//  Created by Georges Kanaan on 6/4/15.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

// Pods
#import <Parse/Parse.h>

// Classes
#import "AppDelegate.h"

// Frameworks
#import <Accounts/Accounts.h>

// Models
#import "DUserWatch.h"

typedef void (^AccountCompletionBlock)(BOOL success, ACAccount * _Nullable account, NSError * _Nullable error);

@interface DUser : PFUser <PFSubclassing>

@property (strong, nonatomic) PFFile * _Nullable profileImage;

@property (strong, nonatomic) NSString * _Nullable fullName;

// Set of user emails
@property (strong, nonatomic) NSSet * _Nullable blockedEmails;
@property (strong, nonatomic) NSSet * _Nullable contactsEmails;
@property (strong, nonatomic) NSSet * _Nullable favouriteContactsEmails;

@property (strong, nonatomic) NSArray * _Nullable lastSeens;

+ (instancetype _Nullable)currentUser;
+ (instancetype _Nonnull)object;

@property (strong, nonatomic, readonly) NSString * _Nullable facebookUsername;
@property (strong, nonatomic, readonly) NSString * _Nullable twitterUsername;

- (void)selectTwitterAccountWithCompletion:(_Nullable AccountCompletionBlock)completion;
- (void)selectFacebookAccountWithCompletion:(_Nullable AccountCompletionBlock)completion;

- (void)renewCredentials;

+ (void)showSocialServicesAlert;

- (DUserWatch* _Nonnull)watchUser;

@end