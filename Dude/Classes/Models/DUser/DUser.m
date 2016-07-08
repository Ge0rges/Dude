//
//  DUser.m
//  Dude
//
//  Created by Georges Kanaan on 6/4/15.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

#import "DUser.h"

@interface DUser ()

@property (strong, nonatomic) DUser *currentUser;

@property (strong, nonatomic) NSString * _Nullable firstName;
@property (strong, nonatomic) NSString * _Nullable lastName;

@end

@implementation DUser

@dynamic firstName, lastName;
@synthesize lastSeens, profileImage, blockedContacts, contacts, favouriteContacts;

#pragma mark - Initializations
+ (instancetype _Nullable)userWithRecord:(CKRecord*)record {
  DUser *user = [DUser new];
  
  // Get the profile image
  CKReference *profileImageReference = record[ProfileImageKey];
  
  CKFetchRecordsOperation *profileImageFetchOperation = [[CKFetchRecordsOperation alloc] initWithRecordIDs:@[profileImageReference.recordID]];
  profileImageFetchOperation.fetchRecordsCompletionBlock = ^(NSDictionary <CKRecordID * , CKRecord *> * __nullable recordsByRecordID, NSError * __nullable operationError) {
    if (operationError) {
      NSLog(@"error fetching profile image of user");
    
    } else if (recordsByRecordID) {
      for (CKRecord *record in [recordsByRecordID allKeys]) {
        user.profileImage = record[ProfileImageKey];
      }
    }
  };
  
  [[[CKContainer defaultContainer] publicCloudDatabase] addOperation:profileImageFetchOperation];
  
  user.recordID = record.recordID;
  user.userRecord = record;
  user.blockedContacts = record[BlockedContactsKey];
  user.favouriteContacts = record[FavouriteContactsKey];
  user.contacts = record[ContactsKey];
  
  for (CKReference *lastSeenReference in (NSArray *)record[LastSeensKey]) {
    CKFetchRecordsOperation *lastSeenFetchOperation = [[CKFetchRecordsOperation alloc] initWithRecordIDs:@[lastSeenReference.recordID]];
    lastSeenFetchOperation.fetchRecordsCompletionBlock = ^(NSDictionary <CKRecordID * , CKRecord *> * __nullable recordsByRecordID, NSError * __nullable operationError) {
      if (operationError) {
        NSLog(@"error fetching a lastSeen of the user");
        
      } else if (recordsByRecordID) {
        for (CKRecord *record in [recordsByRecordID allKeys]) {
          NSMutableArray *lastSeens = [NSMutableArray arrayWithArray:user.lastSeens];
          [lastSeens addObject:record];
          
          user.lastSeens = lastSeens;
        }
      }
    };
    
    [[[CKContainer defaultContainer] publicCloudDatabase] addOperation:lastSeenFetchOperation];
  }
  
  user.lastSeens = record[LastSeensKey];
  
  [user fetchName];

  return user;
}

+ (instancetype _Nullable)currentUser {
  // perform cache checks, update them if necessarya nd return nil.
  CKRecordID *currentUserRecordID = [[NSUserDefaults standardUserDefaults] objectForKey:@"currentUserRecordID"];
  CKRecord *currentUserRecord = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@", currentUserRecordID]];
  
  if (!currentUserRecordID) {
    // Update the cache
    [[CKContainer defaultContainer] fetchUserRecordIDWithCompletionHandler:^(CKRecordID * _Nullable recordID, NSError * _Nullable error) {
      [[NSUserDefaults standardUserDefaults] setObject:recordID forKey:@"currentUserRecordID"];
      [[NSUserDefaults standardUserDefaults] synchronize];

      DUser *user = [[DUser alloc] init];
      
      user.recordID = recordID;
      
      [user fetchWithSuccessBlock:^(DUser * _Nullable currentUser) {
        [[NSUserDefaults standardUserDefaults] setObject:currentUser forKey:[NSString stringWithFormat:@"%@", user.recordID]];
        [[NSUserDefaults standardUserDefaults] synchronize];

      } failureBlock:nil];
      
    }];
    
    return nil;
    
  } else if (!currentUserRecord) {
    // Update the cache
    DUser *user = [[DUser alloc] init];
    
    user.recordID = currentUserRecordID;
    
    [user fetchWithSuccessBlock:^(DUser * _Nullable currentUser) {
      [[NSUserDefaults standardUserDefaults] setObject:currentUser forKey:[NSString stringWithFormat:@"%@", currentUser.recordID]];
      [[NSUserDefaults standardUserDefaults] synchronize];

    } failureBlock:nil];
    
    return user;
  }
  
  return [DUser userWithRecord:currentUserRecord];
}


#pragma mark - Fetching
- (void)fetchWithSuccessBlock:(void(^_Nullable)(DUser * _Nullable fetchedUser))successBlock failureBlock:(void(^_Nullable)(NSError * _Nullable error))failureBlock {
  [[[CKContainer defaultContainer] publicCloudDatabase] fetchRecordWithID:self.recordID completionHandler:^(CKRecord * _Nullable record, NSError * _Nullable error) {

    if (error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        failureBlock(error);
      });
      
    } else if (record) {
      // Update the cache
      [[NSUserDefaults standardUserDefaults] setObject:record forKey:[NSString stringWithFormat:@"%@", self.recordID]];
      [[NSUserDefaults standardUserDefaults] synchronize];

      dispatch_async(dispatch_get_main_queue(), ^{
        successBlock([DUser userWithRecord:record]);
      });
    }
  }];
}

- (instancetype _Nullable)fetchFromCache {
  if (!self.recordID) {
    return nil;
  }
  
  return [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@", self.recordID]];
}

- (void)fetchName {
  [[CKContainer defaultContainer] discoverUserInfoWithUserRecordID:self.recordID completionHandler:^(CKDiscoveredUserInfo * _Nullable userInfo, NSError * _Nullable error) {
    self.firstName = userInfo.displayContact.givenName;
    self.lastName = userInfo.displayContact.familyName;
  }];
}

#pragma mark - Saving
- (void)saveWithCompletion:(void(^_Nullable)(CKRecord * _Nullable record, NSError * _Nullable error))completionBlock {
  [[[CKContainer defaultContainer] privateCloudDatabase] saveRecord:self.userRecord completionHandler:completionBlock];
}

#pragma mark - Setters and Getters

- (void)setLastSeens:(NSArray *)lastSeensLcl {
  self.userRecord[LastSeensKey] = lastSeensLcl;
  self.lastSeens = lastSeensLcl;
}

- (void)setProfileImage:(NSData *)profileImageLcl {
  self.userRecord[ProfileImageKey] = profileImageLcl;
  self.profileImage = profileImageLcl;
}

- (void)setBlockedContacts:(NSSet *)blockedContactsLcl {
  self.userRecord[BlockedContactsKey] = [blockedContactsLcl allObjects];
  self.blockedContacts = blockedContactsLcl;
}

- (void)setContacts:(NSSet *)contactsLcl {
  self.userRecord[ContactsKey] = [contactsLcl allObjects];
  self.contacts = contactsLcl;
}

- (void)setFavouriteContacts:(NSSet *)favouriteContactsLcl {
  self.userRecord[FavouriteContactsKey] = [favouriteContactsLcl allObjects];
  self.favouriteContacts = favouriteContactsLcl;
}

#pragma mark - Logout
+ (void)logOut {
  // Create the userunique keys
  NSString *contactsKey = [NSString stringWithFormat:@"contact%@", [DUser currentUser].recordID];
  
  // Clear the saved contacts for this username
  [[NSUserDefaults standardUserDefaults] setObject:nil forKey:contactsKey];
  
  // Clear twitter & facebook preferences for this device
  [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"twitterAccountID"];
  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"askTwitter"];
  
  [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"facebookAccountID"];
  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"askFacebook"];
  
  [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"currentUserRecordID"];
  
  // Sync NSUserDefaults
  [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Twitter & Facebook
- (NSString* _Nonnull)CurrentUserTwitterUsername {
  // If twitter return user account
  ACAccountStore *accountStore = [ACAccountStore new];
  ACAccount *account = [accountStore accountWithIdentifier:[[NSUserDefaults standardUserDefaults] stringForKey:@"twitterAccountID"]];
  
  return (account) ? [NSString stringWithFormat:@"@%@", account.username] : @"No Account Selected";
}

- (NSString* _Nonnull)CurrentUserFacebookUsername {
  // If twitter return user account
  ACAccountStore *accountStore = [ACAccountStore new];
  ACAccount *account = [accountStore accountWithIdentifier:[[NSUserDefaults standardUserDefaults] stringForKey:@"facebookAccountID"]];
  
  return (account) ? account.username : @"No Account Selected";
}

- (void)selectTwitterAccountWithCompletion:(_Nullable AccountCompletionBlock)completion {
  ACAccountStore *accountStore = [ACAccountStore new];
  ACAccountType *twitterTypeAccount = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
  
  [accountStore requestAccessToAccountsWithType:twitterTypeAccount options:nil completion:^(BOOL granted, NSError *error) {
    if (granted && !error) {
      // Check if there are any Twitter accounts
      NSArray *accounts = [accountStore accountsWithAccountType:twitterTypeAccount];
      if (!accounts || accounts.count == 0) {
        if (completion) completion(YES, nil, [NSError errorWithDomain:@"No Accounts" code:404 userInfo:nil]);
        return;
      }
      
      if (accounts.count > 1) {
        [self showSelectionAlertControllerWithAccount:accounts andCompletionHandler:completion forTwitter:YES];
        
      } else {
        ACAccount *account = [accounts lastObject];
        [[NSUserDefaults standardUserDefaults] setObject:account.identifier forKey:@"twitterAccountID"];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"askTwitter"];
        
        if (completion) completion(granted, account, error);
      }
      
    } else {
      [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"askTwitter"];
      
      if (completion) completion(granted, nil, error);
    }
  }];
}

- (void)selectFacebookAccountWithCompletion:(_Nullable AccountCompletionBlock)completion {
  ACAccountStore *accountStore = [ACAccountStore new];
  
  ACAccountType *facebookTypeAccount = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
  
  NSDictionary *options = @{
                            ACFacebookAppIdKey: @"374328212774790",
                            ACFacebookPermissionsKey: @[@"user_birthday", @"publish_actions"],
                            ACFacebookAudienceKey: ACFacebookAudienceEveryone
                            };
  
  [accountStore requestAccessToAccountsWithType:facebookTypeAccount options:options completion:^(BOOL granted, NSError *error) {
    if(granted) {
      // Check if there are any Faceboook accounts
      NSArray *accounts = [accountStore accountsWithAccountType:facebookTypeAccount];
      if (!accounts || accounts.count == 0) {
        if (completion)  completion(YES, nil, [NSError errorWithDomain:@"No Accounts" code:404 userInfo:nil]);
        return;
      }
      
      if (accounts.count > 1) {
        [self showSelectionAlertControllerWithAccount:accounts andCompletionHandler:completion forTwitter:NO];
        
      } else {
        ACAccount *account = [accounts lastObject];
        [[NSUserDefaults standardUserDefaults] setObject:account.identifier forKey:@"facebookAccountID"];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"askFacebook"];
        
        if (completion) completion(granted, account, error);
      }
      
    } else {
      [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"askFacebook"];
      
      if (completion) completion(granted, nil, error);
    }
  }];
}

- (void)renewCredentials {
  ACAccountStore *accountStore = [ACAccountStore new];
  ACAccount *twitterAccount = [accountStore accountWithIdentifier:[[NSUserDefaults standardUserDefaults] stringForKey:@"twitterAccountID"]];
  ACAccount *facebookAccount = [accountStore accountWithIdentifier:[[NSUserDefaults standardUserDefaults] stringForKey:@"facebookAccountID"]];
  
  if (twitterAccount) {
    [accountStore renewCredentialsForAccount:twitterAccount completion:nil];
  }
  
  if (facebookAccount) {
    [accountStore renewCredentialsForAccount:facebookAccount completion:nil];
  }
}

- (void)showSelectionAlertControllerWithAccount:(NSArray* _Nonnull)accounts andCompletionHandler:(AccountCompletionBlock)completion forTwitter:(BOOL)twitter {
  dispatch_async(dispatch_get_main_queue(), ^{
    NSString *title = (twitter) ? @"Which Twitter account would you like to use?" : @"Which Facebook account would you like to use?" ;
    
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    for (ACAccount *account in accounts) {
      [ac addAction:[UIAlertAction actionWithTitle:account.username style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[NSUserDefaults standardUserDefaults] setObject:account.identifier forKey:(twitter) ? @"twitterAccountID" : @"facebookAccountID"];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:(twitter) ? @"askTwitter" : @"askFacebook"];
                
        if (completion) completion(YES, account, nil);
      }]];
    }
    
    [ac addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    // Present the alert on the visible view controller
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate.visibleViewController presentViewController:ac animated:YES completion:nil];
  });
}

#pragma mark - Other helpers
+ (void)showSocialServicesAlert {
  dispatch_async(dispatch_get_main_queue(), ^{
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Error" message:@"You must be logged in to either Twitter or Facebook and allow access to social accounts to be able to use them within the app." preferredStyle:UIAlertControllerStyleAlert];
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]]) {
      [ac addAction:[UIAlertAction actionWithTitle:@"Open Preferences" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
      }]];
    }
    
    [ac addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
    
    // Present the alert on the visible view controller
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate.visibleViewController presentViewController:ac animated:YES completion:nil];
  });
}

@end
