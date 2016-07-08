//
//  DUserWatch.m
//  Dude
//
//  Created by Georges Kanaan on 29/11/15.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

#import "DUserWatch.h"

// Encoding keys
NSString* const WProfileImageKey = @"Picture";
NSString* const FullNameKey = @"fullName";

@implementation DUserWatch

@synthesize profileImage, fullName, recordIDData;

#pragma mark - NSCoding
- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeDataObject:self.recordIDData];
  [aCoder encodeObject:self.fullName forKey:FullNameKey];
  [aCoder encodeObject:self.profileImage forKey:WProfileImageKey];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super init];
  
  self.recordIDData = [aDecoder decodeDataObject];
  self.fullName = [aDecoder decodeObjectForKey:FullNameKey];
  self.profileImage = [aDecoder decodeObjectForKey:WProfileImageKey];
  
  return self;
}

@end
