//
//  WatchConnectivityManager.m
//  Dude
//
//  Created by Georges Kanaan on 16/03/2016.
//  Copyright © 2016 Georges Kanaan. All rights reserved.
//

#import "WatchConnectivityManager.h"

// Models
#import "DUser.h"

// Managers
#import "MessagesManager.h"

// Constants
#import "Constants.h"

@interface WatchConnectivityManager () <WCSessionDelegate>

@property (strong, nonatomic) WCSession *session;

@end

@implementation WatchConnectivityManager

+ (instancetype _Nullable)sharedManager {
  static WatchConnectivityManager *sharedWatchConnectivityManager = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedWatchConnectivityManager = [self new];    
  });
  
  return sharedWatchConnectivityManager;
}

- (BOOL)activateSession {
  self.session = [WCSession defaultSession];
  self.session.delegate = self;
  [self.session activateSession];
  
  return self.session.isReachable;
}

#pragma mark - Setter

#pragma mark - WCSessionDelegate
- (void)session:(WCSession *)session didReceiveMessage:(nonnull NSDictionary<NSString *,id> *)message {
  // Send a message
  if ([message[WatchRequestTypeKey] isEqualToString:WatchRequestSendMessageValue]) {
    CKRecordID *userRecordID = [NSKeyedUnarchiver unarchiveObjectWithData:message[WatchContactsKey]];
    [[[CKContainer defaultContainer] publicCloudDatabase] fetchRecordWithID:userRecordID completionHandler:^(CKRecord * _Nullable record, NSError * _Nullable error) {
      [[MessagesManager sharedInstance] sendMessage:message[WatchMessagesKey] toContact:[DUser userWithRecord:record] withCompletion:nil];
    }];
    
  // Provide messages
  } else if ([message[WatchRequestTypeKey] isEqualToString:WatchRequestMessagesValue]) {
    [[MessagesManager sharedInstance] setLocationForMessageGenerationWithCompletion:^(NSError *error) {
      [session sendMessage:@{WatchMessagesKey: [[MessagesManager sharedInstance] generateMessages:16]} replyHandler:nil errorHandler:nil];
    } latest:YES];
  }
}

- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *,id> *)message replyHandler:(void (^)(NSDictionary<NSString *,id> * _Nonnull))replyHandler {
  // Provide Messages
  if ([message[WatchRequestTypeKey] isEqualToString:WatchRequestMessagesValue]) {
    replyHandler(@{@"success": @YES});
    [[MessagesManager sharedInstance] setLocationForMessageGenerationWithCompletion:^(NSError *error) {
      [session sendMessage:@{WatchMessagesKey: [[MessagesManager sharedInstance] generateMessages:16]} replyHandler:nil errorHandler:nil];
    } latest:YES];
  }
}

@end
