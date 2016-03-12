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

#pragma mark - NSCoding
- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:self.email forKey:EmailKey];
  [aCoder encodeObject:self.fullName forKey:FullNameKey];
  [aCoder encodeObject:self.profileImage forKey:ProfileImageKey];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super init];
  
  self.email = [aDecoder decodeObjectForKey:EmailKey];
  self.fullName = [aDecoder decodeObjectForKey:FullNameKey];
  self.profileImage = [aDecoder decodeObjectForKey:ProfileImageKey];
  
  return self;
}

@end