//
//  DUserWatch.h
//  Dude
//
//  Created by Georges Kanaan on 29/11/15.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

// Pods
#import <Parse/Parse.h>

@interface DUserWatch : PFUser <PFSubclassing>

@property (strong, nonatomic) PFFile * _Nullable profileImage;

@property (strong, nonatomic) NSString * _Nullable fullName;

@property (strong, nonatomic) NSString * _Nullable email;

+ (instancetype _Nonnull)object;

@end