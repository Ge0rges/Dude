// UIImage+Alpha.h
// Created by Trevor Harmon on 9/20/09.
// Free for personal or commercial use, with or without modification.
// No warranty is expressed or implied.

// Helper methods for adding an alpha layer to an image

#import <UIKit/UIKit.h>

@interface UIImage (Alpha)
- (BOOL)hasAlpha;
- (UIImage* _Nonnull)imageWithAlpha;
- (UIImage* _Nonnull)transparentBorderImage:(NSUInteger)borderSize;
- (CGImageRef _Nonnull)newBorderMask:(NSUInteger)borderSize size:(CGSize)size;
@end
