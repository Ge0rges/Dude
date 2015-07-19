//
//  Created by krzysztof.zablocki on 4/13/12.
//
//
//


#import <CoreGraphics/CoreGraphics.h>
#import "UIView+KZLayout.h"


@implementation UIView (KZLayout)

#pragma mark Properties

- (CGFloat)right
{
  return CGRectGetMaxX(self.frame);
}

- (void)setRight:(CGFloat)aRight
{
  CGRect f = self.frame;
  f.origin.x = aRight - f.size.width;
  self.frame = f;
}

- (CGFloat)top
{
  return CGRectGetMinY(self.frame);
}

- (void)setTop:(CGFloat)aTop
{
  CGRect f = self.frame;
  f.origin.y = aTop;
  self.frame = f;
}

- (CGFloat)left
{
  return CGRectGetMinX(self.frame);
}

- (void)setLeft:(CGFloat)aLeft
{
  CGRect f = self.frame;
  f.origin.x = aLeft;
  self.frame = f;
}

- (CGFloat)bottom
{
  return CGRectGetMaxY(self.frame);
}

- (void)setBottom:(CGFloat)aBottom
{
  CGRect f = self.frame;
  f.origin.y = aBottom - f.size.height;
  self.frame = f;
}

#pragma mark Sizing
- (CGFloat)width
{
  return CGRectGetWidth(self.frame);
}

- (void)setWidth:(CGFloat)aWidth
{
  CGRect f = self.frame;
  f.size.width = aWidth;
  self.frame = f;
}

- (CGFloat)height
{
  return CGRectGetHeight(self.frame);
}

- (void)setHeight:(CGFloat)aHeight
{
  CGRect f = self.frame;
  f.size.height = aHeight;
  self.frame = f;
}

#pragma mark - Placement

- (UIView*)placeBelow:(UIView*)view margin:(CGFloat)margin
{
  self.top = view.bottom + margin;
  return self;
}

- (UIView*)placeAbove:(UIView*)view margin:(CGFloat)margin
{
  self.bottom = view.top + margin;
  return self;
}

- (UIView*)placeLeftOf:(UIView*)view margin:(CGFloat)margin
{
  self.right = view.left + margin;
  return self;
}

- (UIView*)placeRightOf:(UIView*)view margin:(CGFloat)margin
{
  self.left = view.right + margin;
  return self;
}

- (UIView*)placeExactlyAs:(UIView*)view
{
  self.frame = view.frame;
  return self;
}

- (UIView*)placeBetween:(UIView*)viewA and:(UIView*)viewB resize:(BOOL)resize
{
  BOOL horizontal = viewA.top == viewB.top;
  if (horizontal) {
    //! swap views
    if (viewA.left > viewB.left) {
      UIView *tmp = viewA;
      viewA = viewB;
      viewB = tmp;
    }
    
    CGFloat spaceBetween = viewB.left - viewB.right;
    CGFloat margin = (spaceBetween - self.width) * 0.5f;
    
    if (resize) {
      self.width = spaceBetween;
      margin = 0;
    }
    
    [self placeRightOf:viewA margin:margin];
  } else {
    //! swap views
    if (viewA.top > viewB.top) {
      UIView *tmp = viewA;
      viewA = viewB;
      viewB = tmp;
    }
    
    CGFloat spaceBetween = viewB.bottom - viewB.top;
    CGFloat margin = (spaceBetween - self.height) * 0.5f;
    
    if (resize) {
      self.height = spaceBetween;
      margin = 0;
    }
    
    [self placeBelow:viewA margin:margin];
  }
  return self;
}

@end