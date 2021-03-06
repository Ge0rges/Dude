//
//  SlidingSegues.m
//  Dude
//
//  Created by Georges Kanaan on 17/08/2015.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

#define kAnimationDuration 0.3

#import "SlidingSegues.h"

@implementation SlidingSegueRL

- (void)perform {
  __block UIViewController *sourceViewController = (UIViewController*)[self sourceViewController];
  __block UIViewController *destinationController = (UIViewController*)[self destinationViewController];
  
  // Prepare the source dest controller
  [sourceViewController.view.superview insertSubview:destinationController.view aboveSubview:sourceViewController.view];
  destinationController.view.transform = CGAffineTransformMakeTranslation(sourceViewController.view.frame.size.width, 0);
  
  // Prepare the source controller
  [UIView animateWithDuration:kAnimationDuration delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
    destinationController.view.transform = CGAffineTransformMakeTranslation(0, 0);
    sourceViewController.view.transform = CGAffineTransformMakeTranslation(-sourceViewController.view.frame.size.width, 0);
    
  } completion:^(BOOL finished) {
    if (sourceViewController.navigationController) {
      [sourceViewController.navigationController pushViewController:destinationController animated:NO];
    } else {
      [sourceViewController presentViewController:destinationController animated:NO completion:nil];
    }
  }];
}

@end

@implementation SlidingSegueLR

- (void)perform {
  __block UIViewController *sourceViewController = (UIViewController*)[self sourceViewController];
  __block UIViewController *destinationController = (UIViewController*)[self destinationViewController];
  
  // Prepare the source dest controller
  [sourceViewController.view.superview insertSubview:destinationController.view aboveSubview:sourceViewController.view];
  destinationController.view.transform = CGAffineTransformMakeTranslation(-sourceViewController.view.frame.size.width, 0);
  
  // Prepare the source controller
  [UIView animateWithDuration:kAnimationDuration delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
    destinationController.view.transform = CGAffineTransformMakeTranslation(0, 0);
    sourceViewController.view.transform = CGAffineTransformMakeTranslation(sourceViewController.view.frame.size.width, 0);
    
  } completion:^(BOOL finished) {
    if (destinationController.navigationController) {
      [destinationController.navigationController popViewControllerAnimated:NO];
    } else {
      [sourceViewController dismissViewControllerAnimated:NO completion:nil];
    }
  }];
}

@end