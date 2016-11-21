//
//  CloudKitManager.h
//  Dude
//
//  Created by Georges Kanaan on 13/09/2016.
//  Copyright © 2016 Georges Kanaan. All rights reserved.
//

// Frameworks
#import <Foundation/Foundation.h>
#import <CloudKit/CloudKit.h>

// Models
#import "DUser.h"

@interface CloudKitManager : NSObject

// Subscription
+ (void)setupSubscriptions;

// Fetching
+ (void)fetchCurrentUserWithSuccessBlock:(void(^ _Nullable)(CKRecord * _Nullable currentUserRecord))successBlock failureBlock:(void(^ _Nullable)(NSError * _Nullable error))failureBlock preferCache:(BOOL)fromCache;
+ (void)fetchUserWithRecordID:(CKRecordID * _Nonnull)userRecordID successBlock:(void(^ _Nullable)(CKRecord * _Nullable userRecord))successBlock failureBlock:(void(^ _Nullable)(NSError * _Nullable error))failureBlock preferCache:(BOOL)fromCache;

// Caching
+ (CKRecord * _Nullable)userRecordFromCache:(CKRecordID * _Nonnull)userRecordID;
+ (void)saveUserRecordToCache:(CKRecord * _Nonnull)userRecord;

// User Registration/Log on
+ (void)logIn:(void (^ _Nullable)(BOOL loggedIn, CKRecord * _Nullable results, NSError * _Nullable error))completionHandler;
+ (void)logOut;
+ (void)registerNewUserWithProfileImage:(UIImage * _Nonnull)profileImage userName:(NSString * _Nonnull)fullName completionHandler:(void (^ _Nullable)(BOOL registered, CKRecord * _Nullable results, NSError * _Nullable error))completionHandler;

// User Properties
+ (void)loadFriendsToCurrentUserWithSuccessBlock:(void(^ _Nullable)(NSArray * _Nullable friends))successBlock failureBlock:(void(^ _Nullable)(NSError * _Nullable error))failureBlock;
+ (CKRecordID * _Nullable)currentUserRecordID;

// User Modifications
+ (void)setProfileImageForUser:(CKRecord * _Nonnull)userRecord profileImage:(UIImage * _Nonnull)profileImage completion:(void (^ _Nullable)(BOOL success, NSError * _Nullable error))completionHandler;

@end
