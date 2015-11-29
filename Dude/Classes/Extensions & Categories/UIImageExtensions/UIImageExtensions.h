//
//  UIImageExtensions.h
//  Dude
//
//  Created by Georges Kanaan on 3/11/15.
//  Copyright (c) 2015 Georges Kanaan. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UIImage+Alpha.h"
#import "UIImage+Resize.h"
#import "UIImage+RoundedCorner.h"

@interface UIImage (Blur)
+ (UIImage*)blurredScreenshotOfView:(UIView*)view;

// WWDC 2013 image effects
- (UIImage*)applyBlurWithRadius:(CGFloat)blurRadius tintColor:(UIColor*)tintColor saturationDeltaFactor:(CGFloat)saturationDeltaFactor maskImage:(UIImage*)maskImage;
@end