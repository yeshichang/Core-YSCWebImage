/*
 * This file is part of the YSCWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "YSCWebImageCompat.h"
#import "UIImage+YSCMultiFormat.h"

#if !__has_feature(objc_arc)
    #error YSCWebImage is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif

#if !OS_OBJECT_USE_OBJC
    #error YSCWebImage need ARC for dispatch object
#endif

inline UIImage *YSCScaledImageForKey(NSString * _Nullable key, UIImage * _Nullable image) {
    if (!image) {
        return nil;
    }
    
#if YSC_MAC
    return image;
#elif YSC_UIKIT || YSC_WATCH
    if ((image.images).count > 0) {
        NSMutableArray<UIImage *> *scaledImages = [NSMutableArray array];

        for (UIImage *tempImage in image.images) {
            [scaledImages addObject:YSCScaledImageForKey(key, tempImage)];
        }
        
        UIImage *animatedImage = [UIImage animatedImageWithImages:scaledImages duration:image.duration];
        if (animatedImage) {
            animatedImage.YSC_imageLoopCount = image.YSC_imageLoopCount;
        }
        return animatedImage;
    } else {
#if YSC_WATCH
        if ([[WKInterfaceDevice currentDevice] respondsToSelector:@selector(screenScale)]) {
#elif YSC_UIKIT
        if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
#endif
            CGFloat scale = 1;
            if (key.length >= 8) {
                NSRange range = [key rangeOfString:@"@2x."];
                if (range.location != NSNotFound) {
                    scale = 2.0;
                }
                
                range = [key rangeOfString:@"@3x."];
                if (range.location != NSNotFound) {
                    scale = 3.0;
                }
            }

            UIImage *scaledImage = [[UIImage alloc] initWithCGImage:image.CGImage scale:scale orientation:image.imageOrientation];
            image = scaledImage;
        }
        return image;
    }
#endif
}

NSString *const YSCWebImageErrorDomain = @"YSCWebImageErrorDomain";
