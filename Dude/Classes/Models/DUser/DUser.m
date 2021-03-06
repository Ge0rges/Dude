//
//  DUser.m
//  Dude
//
//  Created by Georges Kanaan on 6/4/15.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

#import "DUser.h"

// Pods
#import <Parse/PFObject+Subclass.h>

extern NSString* const ProfileImageKey; // Defined in DUserWatch which is imported
extern NSString* const FullNameKey; // Defined in DUserWatch which is imported
NSString* const BlockedEmailsKey = @"blockedEmails";
NSString* const ContactsEmailsKey = @"contactsEmails";
NSString* const FavouriteContactsKey = @"favouriteContactsEmails";
NSString* const LastSeensKey = @"lastSeens";

@implementation DUser

@dynamic profileImage, lastSeens, blockedEmails,  contactsEmails, favouriteContactsEmails, fullName;

#pragma mark - Initializations

+ (instancetype)currentUser {
  DUser *currentUser = (DUser*)[super currentUser];
  
  currentUser.profileImage = (PFFile*)currentUser[ProfileImageKey];
  
  currentUser.blockedEmails = [NSSet setWithArray:currentUser[BlockedEmailsKey]];
  currentUser.contactsEmails = [NSSet setWithArray:currentUser[ContactsEmailsKey]];
  currentUser.favouriteContactsEmails = [NSSet setWithArray:currentUser[FavouriteContactsKey]];
  
  currentUser.fullName = currentUser[FullNameKey];
  
  currentUser.lastSeens = currentUser[LastSeensKey];
  
  return currentUser;
}

+ (instancetype)object {
  DUser *user = (DUser*)[super object];
  
  user.profileImage = (PFFile*)user[ProfileImageKey];
    
  user.blockedEmails = [NSSet setWithArray:user[BlockedEmailsKey]];
  user.contactsEmails = [NSSet setWithArray:user[ContactsEmailsKey]];
  user.favouriteContactsEmails = [NSSet setWithArray:user[FavouriteContactsKey]];
  
  user.fullName = user[FullNameKey];
  
  user.lastSeens = user[LastSeensKey];
  
  return user;
}

#pragma mark - WatchOS
- (DUserWatch* _Nonnull)watchUser {
  DUserWatch *watchUser = [DUserWatch new];
  watchUser.profileImage = [UIImage imageWithData:[self.profileImage getData]];
  watchUser.fullName = [self.fullName copy];
  watchUser.email = [self.email copy];
  
  return watchUser;
}

#pragma mark - Support NSSet
- (void)setObject:(nonnull id)object forKey:(nonnull NSString*)key {
  if ([key isEqualToString:@"lastSeens"]) {
    return;
  }

  
  // Make sure we don't have our own email in any of the contact arrays
  if ([object isKindOfClass:[NSSet class]]) {
    NSMutableSet *objectSet = [(NSSet*)object mutableCopy];
    
    if (self.email) {// Check that email isn't nil (it should never be)
      [objectSet removeObject:self.email];
    }
    
    [super setObject:[objectSet allObjects] forKey:key];
  
  } else {
    [super setObject:object forKey:key];
  }
}

- (id)objectForKey:(nonnull NSString*)key {
  id object = [super objectForKey:key];
  
  return object;
}

#pragma mark - Logout
+ (void)logOut {
  // Create the userunique keys
  NSString *contactsKey = [NSString stringWithFormat:@"contact%@", [DUser currentUser].username];
  
  // Clear the saved contacts for this username
  [[NSUserDefaults standardUserDefaults] setObject:nil forKey:contactsKey];
  
  // Clear twitter & facebook preferences for this device
  [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"twitterAccountID"];
  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"askTwitter"];
  
  [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"facebookAccountID"];
  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"askFacebook"];
  
  // Sync NSUserDefaults
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  // Disassociate this user from this device
  [[PFInstallation currentInstallation] setObject:@"" forKey:@"user"];
  [[PFInstallation currentInstallation] save];
  
  [super logOut];
}

#pragma mark - Twitter & Facebook
- (NSString*)twitterUsername {
  // If twitter return user account
  ACAccountStore *accountStore = [ACAccountStore new];
  ACAccount *account = [accountStore accountWithIdentifier:[[NSUserDefaults standardUserDefaults] stringForKey:@"twitterAccountID"]];
  
  return (account) ? [NSString stringWithFormat:@"@%@", account.username] : @"No Account Selected";
}

- (NSString*)facebookUsername {
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

- (void)showSelectionAlertControllerWithAccount:(NSArray*)accounts andCompletionHandler:(AccountCompletionBlock)completion forTwitter:(BOOL)twitter {
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
  
  dispatch_sync(dispatch_get_main_queue(), ^{
    [appDelegate.visibleViewController presentViewController:ac animated:YES completion:nil];
  });
}

#pragma mark - Other helpers
+ (void)showSocialServicesAlert {
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Error" message:@"You must be logged in to either Twitter or Facebook and allow access to social accounts to be able to use them within the app." preferredStyle:UIAlertControllerStyleAlert];
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]]) {
      [ac addAction:[UIAlertAction actionWithTitle:@"Open Preferences" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
      }]];
    }
    
    [ac addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
    
    // Present the alert on the visible view controller
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
  
  dispatch_sync(dispatch_get_main_queue(), ^{
    [appDelegate.visibleViewController presentViewController:ac animated:YES completion:nil];
  });
}

@end
