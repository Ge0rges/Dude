//
//  NSUserDefaultsExtension.m
//  Dude
//
//  Created by Georges Kanaan on 27/08/2016.
//  Copyright © 2016 Georges Kanaan. All rights reserved.
//

#import "NSUserDefaultsExtension.h"

// Frameworks
#import <CloudKit/CloudKit.h>

// Models
#import "DUser.h"

@implementation NSUserDefaults (CloudKit)

- (void)setCKObject:(id)value forKey:(NSString *)defaultName {

  if ([value isKindOfClass:[CKRecordID class]] || [value isKindOfClass:[CKRecord class]] || [value isKindOfClass:[DUser class]]) {
    value = [NSKeyedArchiver archivedDataWithRootObject:value];
  }
  
  [self setObject:value forKey:defaultName];
}

- (id)CKObjectForKey:(NSString *)defaultName {
  if (!defaultName) return nil;
  
  id object = [self objectForKey:defaultName];
  
  if ([object isKindOfClass:[NSData class]]) {
    id tempObj = [NSKeyedUnarchiver unarchiveObjectWithData:object];
    if ([tempObj isKindOfClass:[CKRecordID class]] || [tempObj isKindOfClass:[CKRecord class]] || [tempObj isKindOfClass:[DUser class]]) {
      object = tempObj;
    }
  }
  
  return object;
}

@end
