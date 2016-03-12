//
//  DUserWatch.m
//  Dude
//
//  Created by Georges Kanaan on 29/11/15.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

#import "DUserWatch.h"

// Pods
#import <Parse/PFObject+Subclass.h>

NSString* const ProfileImageKey = @"profileImage";
NSString* const FullNameKey = @"fullName";
NSString* const EmailKey = @"email";

@implementation DUserWatch

@dynamic profileImage, fullName, email;

#pragma mark - Initializations
+ (instancetype)object {
  DUserWatch *user = (DUserWatch*)[super object];
  
  user.profileImage = (PFFile*)user[ProfileImageKey];
  
  user.fullName = user[FullNameKey];
  
  user.email = user[EmailKey];
  
  return user;
}

#pragma mark - Support NSSet
- (void)setObject:(nonnull id)object forKey:(nonnull NSString*)key {
  if ([object isKindOfClass:[NSSet class]]) {
    NSMutableSet *objectSet = [(NSSet*)object mutableCopy];
    
    // Make sure we don't have our own email in any of the contact arrays
    if (self.email) {// Check that email isn't ni, it wil lcause a crash otherwise
      [objectSet removeObject:self.email];
    }
    
    [super setObject:[objectSet allObjects] forKey:key];
  
  } else {
    [super setObject:object forKey:key];
  }
}

- (id)objectForKey:(nonnull NSString*)key {
  id object = [super objectForKey:key];
  
  if ([object isKindOfClass:[NSSet class]]) {
    NSMutableSet *objectSet = [(NSSet*)object mutableCopy];
    [objectSet removeObject:self.email];
    
    return objectSet;
    
  }
  
  return object;
}

@end