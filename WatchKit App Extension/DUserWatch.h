//
//  DUserWatch.h
//  Dude
//
//  Created by Georges Kanaan on 29/11/15.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

// Pods
#import <Parse/Parse.h>

// Framework
#import <WatchKit/WatchKit.h>

@interface DUserWatch : NSObject <NSCoding>

@property (strong, nonatomic) UIImage * _Nullable profileImage;

@property (strong, nonatomic) NSString * _Nullable fullName;

@property (strong, nonatomic) NSString * _Nullable email;

@end