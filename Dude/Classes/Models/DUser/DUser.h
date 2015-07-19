//
//  DUser.h
//  Dude
//
//  Created by Georges Kanaan on 6/4/15.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

// Pods
#import <Parse/Parse.h>

// Frameworks
#import <Accounts/Accounts.h>

typedef void (^AccountCompletionBlock)(BOOL success, ACAccount *account, NSError *error);

@interface DUser : PFUser <PFSubclassing>

@property (strong, nonatomic) PFFile *profileImage;

@property (strong, nonatomic, readonly) NSString *facebookUsername;
@property (strong, nonatomic, readonly) NSString *twitterUsername;

@property (strong, nonatomic) NSString *fullName;

// Set of user emails
@property (strong, nonatomic) NSSet *blockedEmails;
@property (strong, nonatomic) NSSet *contactsEmails;
@property (strong, nonatomic) NSSet *favouriteContactsEmails;

@property (strong, nonatomic) NSDictionary *lastSeens;

+ (instancetype)currentUser;
+ (instancetype)object;

- (void)selectTwitterAccountWithCompletion:(AccountCompletionBlock)completion;
- (void)selectFacebookAccountWithCompletion:(AccountCompletionBlock)completion;

- (void)renewCredentials;

+ (void)showSocialServicesAlert;

@end