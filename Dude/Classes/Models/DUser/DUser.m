//
//  DUser.m
//  Dude
//
//  Created by Georges Kanaan on 6/4/15.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

#import "DUser.h"

// Encoding keys
NSString* const ProfileImageKey = @"ProfilePicture";
NSString* const BlockedContactsKey = @"BlockedContacts";
NSString* const ContactsKey = @"Contacts";
NSString* const FavouriteContactsKey = @"FavouriteContacts";
NSString* const LastSeensKey = @"LastSeens";
NSString* const UserRecordKey = @"UserRecord";
NSString* const UserRecordIDKey = @"UserRecordID";
NSString* const FullNameKey = @"Name";


@interface DUser ()

@property (strong, nonatomic) UIImage * _Nullable profileImage;
@property (strong, nonatomic) NSString * _Nullable fullName;
@property (strong, nonatomic) CKRecordID * _Nonnull recordID;
// Set of user record IDs
@property (strong, nonatomic) NSSet<CKReference *> * _Nullable blockedContacts;
@property (strong, nonatomic) NSSet<CKReference *> * _Nullable contacts;
@property (strong, nonatomic) NSSet<CKReference *> * _Nullable favouriteContacts;
// List of assets to records
@property (strong, nonatomic) NSArray * _Nullable lastSeens;

@end


@implementation DUser

@synthesize lastSeens, profileImage, blockedContacts, contacts, favouriteContacts, fullName;

#pragma mark - Initializations

- (instancetype _Nullable)initWithCKRecord:(CKRecord * _Nonnull)userRecord {
  if ((self = [DUser alloc])) {
    CKAsset *profileImageAsset = userRecord[ProfileImageKey];
    self.profileImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:profileImageAsset.fileURL]];
    
    self.recordID = userRecord.recordID;
    self.userRecord = userRecord;
    self.blockedContacts = userRecord[BlockedContactsKey];
    self.contacts = userRecord[ContactsKey];
    self.favouriteContacts = userRecord[FavouriteContactsKey];
    
    self.fullName = userRecord[FullNameKey];
  }
  
  return self;
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:self.userRecord forKey:UserRecordKey];
  [aCoder encodeObject:self.recordID forKey:UserRecordIDKey];
  [aCoder encodeObject:self.lastSeens forKey:LastSeensKey];
  [aCoder encodeObject:self.fullName forKey:FullNameKey];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [DUser new];
  
  self.userRecord = [aDecoder decodeObjectForKey:UserRecordKey];
  self.recordID = [aDecoder decodeObjectForKey:UserRecordIDKey];
  self.lastSeens = [aDecoder decodeObjectForKey:LastSeensKey];
  self.fullName = [aDecoder decodeObjectForKey:FullNameKey];

  return self;
}

#pragma mark - Twitter & Facebook
- (NSString* _Nonnull)CurrentUserTwitterUsername {
  // If twitter return user account
  ACAccountStore *accountStore = [ACAccountStore new];
  ACAccount *account = [accountStore accountWithIdentifier:[NSUserDefaults.standardUserDefaults stringForKey:@"twitterAccountID"]];
  
  return (account) ? [NSString stringWithFormat:@"@%@", account.username] : @"No Account Selected";
}

- (NSString* _Nonnull)CurrentUserFacebookUsername {
  // If twitter return user account
  ACAccountStore *accountStore = [ACAccountStore new];
  ACAccount *account = [accountStore accountWithIdentifier:[NSUserDefaults.standardUserDefaults stringForKey:@"facebookAccountID"]];
  
  return (account) ? account.username : @"No Account Selected";
}

+ (void)selectTwitterAccountWithCompletion:(_Nullable AccountCompletionBlock)completion {
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
        [[self class] showSelectionAlertControllerWithAccount:accounts andCompletionHandler:completion forTwitter:YES];
        
      } else {
        ACAccount *account = [accounts lastObject];
        [NSUserDefaults.standardUserDefaults setObject:account.identifier forKey:@"twitterAccountID"];
        [NSUserDefaults.standardUserDefaults setBool:NO forKey:@"askTwitter"];
        
        if (completion) completion(granted, account, error);
      }
      
    } else {
      [NSUserDefaults.standardUserDefaults setBool:NO forKey:@"askTwitter"];
      
      if (completion) completion(granted, nil, error);
    }
  }];
}

+ (void)selectFacebookAccountWithCompletion:(_Nullable AccountCompletionBlock)completion {
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
        [[self class] showSelectionAlertControllerWithAccount:accounts andCompletionHandler:completion forTwitter:NO];
        
      } else {
        ACAccount *account = [accounts lastObject];
        [NSUserDefaults.standardUserDefaults setObject:account.identifier forKey:@"facebookAccountID"];
        [NSUserDefaults.standardUserDefaults setBool:NO forKey:@"askFacebook"];
        
        if (completion) completion(granted, account, error);
      }
      
    } else {
      [NSUserDefaults.standardUserDefaults setBool:NO forKey:@"askFacebook"];
      
      if (completion) completion(granted, nil, error);
    }
  }];
}

- (void)renewCredentials {
  ACAccountStore *accountStore = [ACAccountStore new];
  ACAccount *twitterAccount = [accountStore accountWithIdentifier:[NSUserDefaults.standardUserDefaults stringForKey:@"twitterAccountID"]];
  ACAccount *facebookAccount = [accountStore accountWithIdentifier:[NSUserDefaults.standardUserDefaults stringForKey:@"facebookAccountID"]];
  
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
        [NSUserDefaults.standardUserDefaults setObject:account.identifier forKey:(twitter) ? @"twitterAccountID" : @"facebookAccountID"];
        [NSUserDefaults.standardUserDefaults setBool:NO forKey:(twitter) ? @"askTwitter" : @"askFacebook"];
                
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
