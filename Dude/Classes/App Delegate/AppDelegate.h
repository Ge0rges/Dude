//
//  AppDelegate.h
//  Dude
//
//  Created by Georges Kanaan on 11/20/14.
//  Copyright (c) 2014 Georges Kanaan. All rights reserved.
//

// Frameworks
#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

// Constants
#import "Constants.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    NSURL *url;
    
    MKMapItem *mapItem;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UIViewController *visibleViewController;

@end