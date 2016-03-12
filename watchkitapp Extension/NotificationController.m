//
//  NotificationController.m
//  Dude WatchKit Extension
//
//  Created by Georges Kanaan on 2/14/15.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

#import "NotificationController.h"


@interface NotificationController()

@end


@implementation NotificationController

- (instancetype)init {
    self = [super init];
    if (self){
        // Initialize variables here.
        // Configure interface objects here.
        
    }
    return self;
}

- (void)didReceiveRemoteNotification:(NSDictionary*)remoteNotification withCompletion:(void (^)(WKUserNotificationInterfaceType))completionHandler {
    
    // Set the notification alert
    [self.notificationAlertLabel setText:[[[remoteNotification objectForKey:@"aps"] objectForKey:@"alert"] objectForKey:@"body"]];
        
    // Check if we should show the map
    double latitude = [remoteNotification[@"latitude"] doubleValue];
    double longitude = [remoteNotification[@"longitude"] doubleValue];
    
    if (latitude && longitude) {
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2DMake(latitude, longitude), 500, 500);

        [self.map setRegion:region];
        [self.map addAnnotation:CLLocationCoordinate2DMake(latitude, longitude) withPinColor:WKInterfaceMapPinColorRed];
        [self.map setHidden:NO];
    }
    
    completionHandler(WKUserNotificationInterfaceTypeCustom);
}

@end



