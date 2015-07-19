//
//  Created by krzysztof.zablocki on 4/13/12.
//
//
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIView (KZLayout)

//! allows you to modify view border placement, doesn't change view size
@property (assign, nonatomic) CGFloat right;
@property (assign, nonatomic) CGFloat top;
@property (assign, nonatomic) CGFloat left;
@property (assign, nonatomic) CGFloat bottom;

//! adjust size of views, using frame not bounds (otherwise animations would grow from center)
@property (assign, nonatomic) CGFloat width;
@property (assign, nonatomic) CGFloat height;


//! moves to corresponding position in relation to selected view
- (UIView*)placeBelow:(UIView*)view margin:(CGFloat)margin;
- (UIView*)placeAbove:(UIView*)view margin:(CGFloat)margin;
- (UIView*)placeLeftOf:(UIView*)view margin:(CGFloat)margin;
- (UIView*)placeRightOf:(UIView*)view margin:(CGFloat)margin;

//! place between 2 views, use when 2 views are aligned in one axis, if you don't want to resize it will center between the views
- (UIView*)placeBetween:(UIView*)viewA and:(UIView*)viewB resize:(BOOL)resize;

//! matches other view placement
- (UIView*)placeExactlyAs:(UIView*)view;
@end