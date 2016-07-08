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

@interface DUser : NSObject

@property (strong, nonatomic) NSData * _Nullable profileImage;

@property (strong, nonatomic, readonly) NSString * _Nullable firstName;
@property (strong, nonatomic, readonly) NSString * _Nullable lastName;

@property (strong, nonatomic) CKRecordID * _Nonnull recordID;

@property (strong, nonatomic) CKRecord * _Nonnull userRecord;

// Set of user record IDs
@property (strong, nonatomic) NSSet * _Nullable blockedContacts;
@property (strong, nonatomic) NSSet * _Nullable contacts;
@property (strong, nonatomic) NSSet * _Nullable favouriteContacts;

// List of assets to records
@property (strong, nonatomic) NSArray * _Nullable lastSeens;

@property (strong, nonatomic, readonly) NSString * _Nonnull CurrentUserFacebookUsername;
@property (strong, nonatomic, readonly) NSString * _Nonnull CurrentUserTwitterUsername;

// Init and fetching
+ (instancetype _Nullable)userWithRecord:(CKRecord* _Nonnull)record;
+ (instancetype _Nullable)currentUser;

- (void)fetchWithSuccessBlock:(void(^_Nullable)(DUser * _Nullable fetchedUser))successBlock failureBlock:(void(^_Nullable)(NSError * _Nullable error))failureBlock;
- (instancetype _Nullable)fetchFromCache;// Record ID must be set

// Social Stuff
+ (void)showSocialServicesAlert;

- (void)selectTwitterAccountWithCompletion:(_Nullable AccountCompletionBlock)completion;
- (void)selectFacebookAccountWithCompletion:(_Nullable AccountCompletionBlock)completion;

- (void)renewCredentials;

// Saving
- (void)saveWithCompletion:(void(^_Nullable)(CKRecord * _Nullable record, NSError * _Nullable error))completionBlock;

// Log out
+ (void)logOut;

@end
