//
//  MessagesManager.h
//  Dude
//
//  Created by Georges Kanaan on 3/10/15.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

// Models
#import "DMessage.h"
#import "DUser.h"

//Pods
#import <Parse/Parse.h>

typedef void (^LocationCompletionBlock)(NSError *error);
typedef void (^MessageCompletionBlock)(BOOL success, NSError *error);
typedef void (^UserAddedBlock)(PFObject *object, NSError *error);

@interface MessagesManager : NSObject

+ (instancetype)sharedInstance;

// Message Generation
- (void)setLocationForMessageGenerationWithCompletion:(LocationCompletionBlock)handler;
- (NSArray*)generateMessages:(NSInteger)numberOfMessagesToGenerate;

// Sending messages
- (void)sendMessage:(DMessage*)message toContact:(DUser*)user withCompletion:(MessageCompletionBlock)handler;
- (void)tweetMessage:(DMessage*)message withCompletion:(MessageCompletionBlock)handler;
- (void)postMessage:(DMessage*)message withCompletion:(MessageCompletionBlock)handler;

@end