// UIImage+Resize.h
// Created by Trevor Harmon on 8/5/09.
// Free for personal or commercial use, with or without modification.
// No warranty is expressed or implied.

// Extends the UIImage class to support resizing/cropping
#import <UIKit/UIKit.h>

@interface UIImage (Resize)

- (UIImage* _Nonnull)croppedImage:(CGRect)bounds;
- (UIImage* _Nonnull)thumbnailImage:(NSInteger)thumbnailSize transparentBorder:(NSUInteger)borderSize cornerRadius:(NSUInteger)cornerRadius interpolationQuality:(CGInterpolationQuality)quality;
- (UIImage* _Nonnull)resizedImage:(CGSize)newSize interpolationQuality:(CGInterpolationQuality)quality;
- (UIImage* _Nonnull)resizedImageWithContentMode:(UIViewContentMode)contentMode bounds:(CGSize )bounds interpolationQuality:(CGInterpolationQuality)quality;
- (UIImage* _Nonnull)imageByScalingAndCroppingForSize:(CGSize)targetSize;
- (UIImage* _Nonnull)scaleImageToSize:(CGSize)newSize;

@end
