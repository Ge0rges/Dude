//
//  WatchConnectivityManager.h
//  Dude
//
//  Created by Georges Kanaan on 16/03/2016.
//  Copyright © 2016 Georges Kanaan. All rights reserved.
//

// Frameworks
#import <Foundation/Foundation.h>
#import <WatchConnectivity/WatchConnectivity.h>

@interface WatchConnectivityManager : NSObject

@property (strong, nonatomic, readonly) WCSession * _Nullable session;

+ (instancetype _Nullable)sharedManager;

- (BOOL)activateSession;

@end
