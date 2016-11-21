//
//  CloudKitManager.m
//  Dude
//
//  Created by Georges Kanaan on 13/09/2016.
//  Copyright © 2016 Georges Kanaan. All rights reserved.
//

#import "CloudKitManager.h"

@implementation CloudKitManager

#pragma mark - Account Management
+ (void)loadFriendsToCurrentUserWithSuccessBlock:(void(^)(NSArray *friends))successBlock failureBlock:(void(^)(NSError *error))failureBlock {
  CKRecord *currentUserRecord = [self userRecordFromCache:[self currentUserRecordID]];
  CKQuery *query = [[CKQuery alloc] initWithRecordType:@"Users" predicate:[NSPredicate predicateWithFormat:@"Users = %@", [currentUserRecord recordID]]];
  
  [[[CKContainer defaultContainer] publicCloudDatabase] performQuery:query inZoneWithID:nil completionHandler:^(NSArray *results, NSError *error) {
    if (error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        failureBlock(error);
      });
      
    } else {
      dispatch_async(dispatch_get_main_queue(), ^{
        successBlock(results);
      });
    }
  }];
}

+ (void)logIn:(void (^ _Nullable)(BOOL loggedIn, CKRecord * _Nullable results, NSError * _Nullable error))completionHandler {
  
  [self userIsRegistered:^(BOOL isRegistered, NSArray<CKRecord *> * _Nullable results, NSError * _Nullable error) {
    // Make sure this user exists
    if (isRegistered) {
      
      // Fetch the current User
      [self fetchCurrentUserWithSuccessBlock:^(CKRecord * _Nullable currentUserRecord) {
        
        // Register this device for subscriptions (notifications)
        [self setupSubscriptions];
        
        // Set social accounts for the user (local)
        [DUser selectTwitterAccountWithCompletion:nil];
        [DUser selectFacebookAccountWithCompletion:nil];
        
        // Call the completion handler
        completionHandler(YES, currentUserRecord, nil);
        
      } failureBlock:^(NSError * _Nullable error) {
        completionHandler(NO, nil, error);// Error just call the completionHandler
      
      } preferCache:NO];
      
    } else {
      // Call the completion handler with a "Not Registered error"
      completionHandler(NO, nil, [NSError errorWithDomain:@"Registration" code:404 userInfo:nil]);
    }
  }];
}

+ (void)logOut {
  // Clear twitter & facebook preferences for this device
  [NSUserDefaults.standardUserDefaults setObject:nil forKey:@"twitterAccountID"];
  [NSUserDefaults.standardUserDefaults setBool:YES forKey:@"askTwitter"];
  
  [NSUserDefaults.standardUserDefaults setObject:nil forKey:@"facebookAccountID"];
  [NSUserDefaults.standardUserDefaults setBool:YES forKey:@"askFacebook"];
  
  [NSUserDefaults.standardUserDefaults setObject:nil forKey:@"currentUserRecordID"];
  
  // Sync NSUserDefaults
  [NSUserDefaults.standardUserDefaults synchronize];
}

+ (void)registerNewUserWithProfileImage:(UIImage * _Nonnull)profileImage userName:(NSString * _Nonnull)fullName completionHandler:(void (^ _Nullable)(BOOL registered, CKRecord * _Nullable results, NSError * _Nullable error))completionHandler{
  /*
   1. Check that the current user doesnt have a Users type record in his private databse, if so log him in.
   2. Create Users type record in public database that allows people to see the profile image and name.
   3. Cache everything.
   */
  
  [self userIsRegistered:^(BOOL isRegistered, NSArray<CKRecord *> * _Nullable results, NSError * _Nullable error) {
    // Check for error
    if (error) {
#warning handle
      return;
    }
    
    if (isRegistered) {
      [self logIn:completionHandler];// Log the user in.
    
    } else {
      //2. Create the record
      CKRecord *userRecord = [[CKRecord alloc] initWithRecordType:@"Users"];
      
      //2.a Create the image asset
      NSData *profileImageData = UIImagePNGRepresentation(profileImage);
      
      NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
      NSString *imagePath = [documentsDirectory stringByAppendingPathComponent:@"tempImage"];
      NSURL *imageURL = [NSURL fileURLWithPath:imagePath];
      
      [profileImageData writeToURL:imageURL atomically:YES];
      
      CKAsset *profilePictureAsset = [[CKAsset alloc] initWithFileURL:imageURL];
      
      [userRecord setObject:profilePictureAsset forKey:@"ProfilePicture"];
      
      //2.b Set the name
      userRecord[@"Name"] = fullName;
      
      //2.c Save the record
      [[[CKContainer defaultContainer] publicCloudDatabase] saveRecord:userRecord completionHandler:^(CKRecord * _Nullable record, NSError * _Nullable error) {
        completionHandler(NO, record, error);
        
        //3. Cache and Cleanup!
        if (!error && record) {
          [self saveUserRecordToCache:record];
        }
        
        [[NSFileManager defaultManager] removeItemAtURL:imageURL error:nil];
      }];
    }
  }];
}

+ (void)userIsRegistered:(void (^ _Nullable)(BOOL isRegistered, NSArray<CKRecord *> * _Nullable results, NSError * _Nullable error))completionHandler {
  // A user is registered if it's recordID is associated with a "Users" record in the public database.
  if (![self currentUserRecordID]) {// Check if a recordID is cached, fetch it if not.
    [self fetchCurrentUserWithSuccessBlock:^(CKRecord * _Nullable currentUserRecord) {
      [self userIsRegistered:completionHandler];// Call this method back.
      
    } failureBlock:^(NSError * _Nullable error) {
      completionHandler(nil, nil, error);
    
    }  preferCache:NO];
  
  } else {
    // Use the cached version
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"creatorUserRecordID = %@", [self currentUserRecordID]];
    CKQuery *query = [[CKQuery alloc] initWithRecordType:@"Users" predicate:predicate];
    
    [[[CKContainer defaultContainer] publicCloudDatabase] performQuery:query inZoneWithID:nil completionHandler:^(NSArray *results, NSError *error) {
      if (results.count > 0 && completionHandler) {
        completionHandler(YES, results, error);
        
      } else if (results.count == 0 && completionHandler) {
        completionHandler(NO, results, error);
      }
    }];
  }
}

+ (CKRecordID * _Nullable)currentUserRecordID {
  return [[NSUserDefaults standardUserDefaults] objectForKey:@"currentUserRecordID"];// Set when fetching
}

+ (void)setProfileImageForUser:(CKRecord * _Nonnull)userRecord profileImage:(UIImage * _Nonnull)profileImage completion:(void (^ _Nullable)(BOOL success, NSError * _Nullable error))completionHandler {
  //1 Create the image asset
  NSData *profileImageData = UIImagePNGRepresentation(profileImage);
  
  NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
  NSString *imagePath = [documentsDirectory stringByAppendingPathComponent:@"tempImage"];
  NSURL *imageURL = [NSURL fileURLWithPath:imagePath];
  
  [profileImageData writeToURL:imageURL atomically:YES];
  
  CKAsset *profilePictureAsset = [[CKAsset alloc] initWithFileURL:imageURL];
  
  [userRecord setObject:profilePictureAsset forKey:@"ProfilePicture"];
  
  //2 Save the record
  [[[CKContainer defaultContainer] publicCloudDatabase] saveRecord:userRecord completionHandler:^(CKRecord * _Nullable record, NSError * _Nullable error) {
    if (!error && record) {
      completionHandler(YES, nil);
      
      // Update the cache
      [self saveUserRecordToCache:record];
    
    } else if (error) {
      completionHandler(NO, error);
    }
    
    [[NSFileManager defaultManager] removeItemAtURL:imageURL error:nil];
  }];
}


#pragma mark - Subscription
+ (void)setupSubscriptions {
  CKRecordID *currentUserRecordID = [self currentUserRecordID];
  
  if (!currentUserRecordID) {
    [self fetchCurrentUserWithSuccessBlock:^(CKRecord * _Nullable currentUserRecord) {
      [self setupSubscriptions];
      
    } failureBlock:^(NSError * _Nullable error) {
#warning handle
    } preferCache: NO];
    
    return;
  }
  
  // Subscribe to last seen creation
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ReceiverRecordIDName = %@", currentUserRecordID.recordName];
  CKSubscription *lastSeenSubscription = [[CKSubscription alloc] initWithRecordType:@"LastSeen" predicate:predicate options:CKSubscriptionOptionsFiresOnRecordCreation | CKSubscriptionOptionsFiresOnRecordUpdate];
  
  CKNotificationInfo *lastSeenNotificationInfo = [CKNotificationInfo new];
  lastSeenNotificationInfo.desiredKeys = @[@"Receiver",@"Sender", @"Message"];
  lastSeenNotificationInfo.alertLocalizationArgs = @[@"NotificationAlert"];
  lastSeenNotificationInfo.alertBody = @"%@";
  lastSeenNotificationInfo.shouldBadge = YES;
  lastSeenNotificationInfo.category = @"REPLY_CATEGORY";
  
  [lastSeenSubscription setNotificationInfo:lastSeenNotificationInfo];
  
  [[[CKContainer defaultContainer] publicCloudDatabase] saveSubscription:lastSeenSubscription completionHandler:^(CKSubscription *subscription, NSError *error) {
    if (error) {
      NSLog(@"Well shit. subscription didnt save. lastseen");
    }
  }];
  
  // Subscribe to notification creation
  CKSubscription *notificationSubscription = [[CKSubscription alloc] initWithRecordType:@"Notification" predicate:predicate options:CKSubscriptionOptionsFiresOnRecordCreation];
  
  CKNotificationInfo *notificationInfo = [CKNotificationInfo new];
  notificationInfo.alertLocalizationArgs = @[@"Message"];
  notificationInfo.alertBody = @"%@";
  notificationInfo.shouldBadge = NO;
  
  [notificationSubscription setNotificationInfo:notificationInfo];
  
  [[[CKContainer defaultContainer] publicCloudDatabase] saveSubscription:notificationSubscription completionHandler:^(CKSubscription *subscription, NSError *error) {
    if (error) {
      NSLog(@"Well shit. subscription didnt save. notification");
    }
  }];
  
#pragma mark DEVELOPER ONLY
#if 1
  // Subscribe to notification creation
  NSPredicate *devPredicate = [NSPredicate predicateWithFormat:@"Developer = %@", @1];
  CKSubscription *devNotificationSubscription = [[CKSubscription alloc] initWithRecordType:@"Notification" predicate:devPredicate options:CKSubscriptionOptionsFiresOnRecordCreation];
  
  CKNotificationInfo *devNotificationInfo = [CKNotificationInfo new];
  devNotificationInfo.alertLocalizationArgs = @[@"Message"];
  devNotificationInfo.alertBody = @"Not supported: %@ - Remember to delete the record!";
  devNotificationInfo.shouldBadge = YES;
  
  [devNotificationSubscription setNotificationInfo:notificationInfo];
  
  [[[CKContainer defaultContainer] publicCloudDatabase] saveSubscription:devNotificationSubscription completionHandler:^(CKSubscription *subscription, NSError *error) {
    if (error) {
      NSLog(@"Well shit. subscription didnt save. developer");
    }
  }];
#endif
}


#pragma mark - Fetching
+ (void)fetchCurrentUserWithSuccessBlock:(void(^ _Nullable)(CKRecord * _Nullable currentUserRecord))successBlock failureBlock:(void(^ _Nullable)(NSError * _Nullable error))failureBlock  preferCache:(BOOL)fromCache {
  CKRecordID *currentUserRecordID = [self currentUserRecordID];
  
  if (currentUserRecordID) {// Check if we need to fetch the current user's record ID.
    CKRecord *currentUserCached = [self userRecordFromCache:currentUserRecordID];
    
    if (currentUserCached && fromCache) {// If we have the Record ID and cache is ok, use it.
      successBlock(currentUserCached);
      return;
      
    } else {// Otherwise, fetch the current user (either it doesn't exist, or cache isn't accepted.)
      [self fetchUserWithRecordID:currentUserRecordID successBlock:successBlock failureBlock:failureBlock preferCache:YES];
    }
    
  } else {// Current user Record ID is unknown, fetch it and then fetch the user.
    [[CKContainer defaultContainer] fetchUserRecordIDWithCompletionHandler:^(CKRecordID * _Nullable recordID, NSError * _Nullable error) {
      if (error) {
        failureBlock(error);
        
      } else {
        // Cache the current user record id
        [[NSUserDefaults standardUserDefaults] setCKObject:recordID forKey:@"currentUserRecordID"];
        
        // Fetch the current user
        [self fetchUserWithRecordID:recordID successBlock:successBlock failureBlock:failureBlock preferCache:YES];
      }
    }];
  }
}

+ (void)fetchUserWithRecordID:(CKRecordID * _Nonnull)userRecordID successBlock:(void(^ _Nullable)(CKRecord * _Nullable userRecord))successBlock failureBlock:(void(^ _Nullable)(NSError * _Nullable error))failureBlock preferCache:(BOOL)fromCache {
  
  // Try the cache
  if (fromCache) {
    CKRecord *cachedUser = [self userRecordFromCache:[self currentUserRecordID]];
    if (cachedUser) {
      successBlock(cachedUser);
      return;
    }
  }
  
  // Fetch the user
  CKQuery *query = [[CKQuery alloc] initWithRecordType:@"Users" predicate:[NSPredicate predicateWithFormat:@"creatorUserRecordID = %@", userRecordID]];
  [[[CKContainer defaultContainer] publicCloudDatabase] performQuery:query inZoneWithID:nil completionHandler:^(NSArray *results, NSError *error) {
    if (error) {
      failureBlock(error);
      
    } else {
      [self saveUserRecordToCache:[results firstObject]];// Always cache
      
      successBlock([results firstObject]);
    }
  }];
}

#pragma mark - Caching
+ (CKRecord * _Nullable)userRecordFromCache:(CKRecordID * _Nonnull)userRecordID {
  return [[NSUserDefaults standardUserDefaults] CKObjectForKey:[NSString stringWithFormat:@"%@", userRecordID]];
}

+ (void)saveUserRecordToCache:(CKRecord * _Nonnull)userRecord {
  [[NSUserDefaults standardUserDefaults] setCKObject:userRecord forKey:[NSString stringWithFormat:@"%@", userRecord.recordID]];
  
  [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
