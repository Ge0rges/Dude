//
//  MainNavigationController.m
//  Dude
//
//  Created by Georges Kanaan on 15/09/2015.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

#import "MainNavigationController.h"

// Classes
#import "SlidingSegues.h"

@interface MainNavigationController ()

@end

@implementation MainNavigationController


#pragma mark - Navigation
- (UIStoryboardSegue*)segueForUnwindingToViewController:(UIViewController *)toViewController fromViewController:(UIViewController *)fromViewController identifier:(NSString *)identifier {
  return [SlidingSegueLR segueWithIdentifier:identifier source:fromViewController destination:toViewController performHandler:^{}];
}

@end
