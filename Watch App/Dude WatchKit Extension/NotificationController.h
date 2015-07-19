//
//  NotificationController.h
//  Dude WatchKit Extension
//
//  Created by Georges Kanaan on 2/14/15.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface NotificationController : WKUserNotificationInterfaceController

@property (strong, nonatomic) IBOutlet WKInterfaceMap *map;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *notificationAlertLabel;

@end
