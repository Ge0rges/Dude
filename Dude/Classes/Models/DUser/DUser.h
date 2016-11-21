//
//  DUser.h
//  Dude
//
//  Created by Georges Kanaan on 6/4/15.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

// Classes
#import "AppDelegate.h"

// Frameworks
#import <Accounts/Accounts.h>
#import <CloudKit/CloudKit.h>

typedef void (^AccountCompletionBlock)(BOOL success, ACAccount * _Nullable account, NSError * _Nullable error);

@interface DUser : NSObject <NSCoding>

@property (strong, nonatomic, readonly) UIImage * _Nullable profileImage;

@property (strong, nonatomic, readonly) NSString * _Nullable fullName;

@property (strong, nonatomic, readonly) CKRecordID * _Nonnull recordID;

@property (strong, nonatomic) CKRecord * _Nonnull userRecord;

// Set of user record IDs
@property (strong, nonatomic, readonly) NSSet<CKReference *> * _Nullable blockedContacts;
@property (strong, nonatomic, readonly) NSSet<CKReference *> * _Nullable contacts;
@property (strong, nonatomic, readonly) NSSet<CKReference *> * _Nullable favouriteContacts;

// List of assets to records
@property (strong, nonatomic, readonly) NSArray * _Nullable lastSeens;

@property (strong, nonatomic, readonly) NSString * _Nonnull CurrentUserFacebookUsername;
@property (strong, nonatomic, readonly) NSString * _Nonnull CurrentUserTwitterUsername;

// Init
- (instancetype _Nullable)initWithCKRecord:(CKRecord * _Nonnull)userRecord;

// Social Stuff
+ (void)showSocialServicesAlert;

+ (void)selectTwitterAccountWithCompletion:(_Nullable AccountCompletionBlock)completion;
+ (void)selectFacebookAccountWithCompletion:(_Nullable AccountCompletionBlock)completion;

- (void)renewCredentials;

@end
