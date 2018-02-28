/*
 * This file is part of the YSCWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImage+YSCMultiFormat.h"

#import "objc/runtime.h"
#import "YSCWebImageCodersManager.h"

@implementation UIImage (YSCMultiFormat)

#if YSC_MAC
- (NSUInteger)YSC_imageLoopCount {
    NSUInteger imageLoopCount = 0;
    for (NSImageRep *rep in self.representations) {
        if ([rep isKindOfClass:[NSBitmapImageRep class]]) {
            NSBitmapImageRep *bitmapRep = (NSBitmapImageRep *)rep;
            imageLoopCount = [[bitmapRep valueForProperty:NSImageLoopCount] unsignedIntegerValue];
            break;
        }
    }
    return imageLoopCount;
}

- (void)setYSC_imageLoopCount:(NSUInteger)YSC_imageLoopCount {
    for (NSImageRep *rep in self.representations) {
        if ([rep isKindOfClass:[NSBitmapImageRep class]]) {
            NSBitmapImageRep *bitmapRep = (NSBitmapImageRep *)rep;
            [bitmapRep setProperty:NSImageLoopCount withValue:@(YSC_imageLoopCount)];
            break;
        }
    }
}

#else

- (NSUInteger)YSC_imageLoopCount {
    NSUInteger imageLoopCount = 0;
    NSNumber *value = objc_getAssociatedObject(self, @selector(YSC_imageLoopCount));
    if ([value isKindOfClass:[NSNumber class]]) {
        imageLoopCount = value.unsignedIntegerValue;
    }
    return imageLoopCount;
}

- (void)setYSC_imageLoopCount:(NSUInteger)YSC_imageLoopCount {
    NSNumber *value = @(YSC_imageLoopCount);
    objc_setAssociatedObject(self, @selector(YSC_imageLoopCount), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
#endif

+ (nullable UIImage *)YSC_imageWithData:(nullable NSData *)data {
    return [[YSCWebImageCodersManager sharedInstance] decodedImageWithData:data];
}

- (nullable NSData *)YSC_imageData {
    return [self YSC_imageDataAsFormat:YSCImageFormatUndefined];
}

- (nullable NSData *)YSC_imageDataAsFormat:(YSCImageFormat)imageFormat {
    NSData *imageData = nil;
    if (self) {
        imageData = [[YSCWebImageCodersManager sharedInstance] encodedDataWithImage:self format:imageFormat];
    }
    return imageData;
}


@end
