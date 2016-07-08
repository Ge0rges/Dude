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

typedef void (^LocationCompletionBlock)( NSError * _Nullable error);
typedef void (^MessageCompletionBlock)(BOOL success, NSError *_Nullable error);

@interface MessagesManager : NSObject

+ (instancetype _Nullable)sharedInstance;

// Message Generation
- (void)setLocationForMessageGenerationWithCompletion:(_Nonnull LocationCompletionBlock)handler latest:(BOOL)latest;
- (NSArray* _Nonnull)generateMessages:(NSInteger)numberOfMessagesToGenerate;

// Sending messages
- (void)sendMessage:(DMessage* _Nonnull)message toContact:(DUser* _Nonnull)user withCompletion:(_Nullable MessageCompletionBlock)handler;
- (void)tweetMessage:(DMessage* _Nonnull)message withCompletion:(_Nullable MessageCompletionBlock)handler;
- (void)postMessage:(DMessage* _Nonnull)message withCompletion:(_Nullable MessageCompletionBlock)handler;

@end