/*
 * This file is part of the YSCWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "YSCWebImageGIFCoder.h"
#import "NSImage+YSCWebCache.h"
#import <ImageIO/ImageIO.h>
#import "NSData+YSCImageContentType.h"
#import "UIImage+YSCMultiFormat.h"
#import "YSCWebImageCoderHelper.h"

@implementation YSCWebImageGIFCoder

+ (instancetype)sharedCoder {
    static YSCWebImageGIFCoder *coder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        coder = [[YSCWebImageGIFCoder alloc] init];
    });
    return coder;
}

#pragma mark - Decode
- (BOOL)canDecodeFromData:(nullable NSData *)data {
    return ([NSData YSC_imageFormatForImageData:data] == YSCImageFormatGIF);
}

- (UIImage *)decodedImageWithData:(NSData *)data {
    if (!data) {
        return nil;
    }
    
#if YSC_MAC
    return [[UIImage alloc] initWithData:data];
#else
    
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    if (!source) {
        return nil;
    }
    size_t count = CGImageSourceGetCount(source);
    
    UIImage *animatedImage;
    
    if (count <= 1) {
        animatedImage = [[UIImage alloc] initWithData:data];
    } else {
        NSMutableArray<YSCWebImageFrame *> *frames = [NSMutableArray array];
        
        for (size_t i = 0; i < count; i++) {
            CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, i, NULL);
            if (!imageRef) {
                continue;
            }
            
            float duration = [self YSC_frameDurationAtIndex:i source:source];
#if YSC_WATCH
            CGFloat scale = 1;
            scale = [WKInterfaceDevice currentDevice].screenScale;
#elif YSC_UIKIT
            CGFloat scale = 1;
            scale = [UIScreen mainScreen].scale;
#endif
            UIImage *image = [UIImage imageWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
            CGImageRelease(imageRef);
            
            YSCWebImageFrame *frame = [YSCWebImageFrame frameWithImage:image duration:duration];
            [frames addObject:frame];
        }
        
        NSUInteger loopCount = 0;
        NSDictionary *imageProperties = (__bridge_transfer NSDictionary *)CGImageSourceCopyProperties(source, nil);
        NSDictionary *gifProperties = [imageProperties valueForKey:(__bridge_transfer NSString *)kCGImagePropertyGIFDictionary];
        if (gifProperties) {
            NSNumber *gifLoopCount = [gifProperties valueForKey:(__bridge_transfer NSString *)kCGImagePropertyGIFLoopCount];
            if (gifLoopCount) {
                loopCount = gifLoopCount.unsignedIntegerValue;
            }
        }
        
        animatedImage = [YSCWebImageCoderHelper animatedImageWithFrames:frames];
        animatedImage.YSC_imageLoopCount = loopCount;
    }
    
    CFRelease(source);
    
    return animatedImage;
#endif
}

- (float)YSC_frameDurationAtIndex:(NSUInteger)index source:(CGImageSourceRef)source {
    float frameDuration = 0.1f;
    CFDictionaryRef cfFrameProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil);
    NSDictionary *frameProperties = (__bridge NSDictionary *)cfFrameProperties;
    NSDictionary *gifProperties = frameProperties[(NSString *)kCGImagePropertyGIFDictionary];
    
    NSNumber *delayTimeUnclampedProp = gifProperties[(NSString *)kCGImagePropertyGIFUnclampedDelayTime];
    if (delayTimeUnclampedProp) {
        frameDuration = [delayTimeUnclampedProp floatValue];
    } else {
        NSNumber *delayTimeProp = gifProperties[(NSString *)kCGImagePropertyGIFDelayTime];
        if (delayTimeProp) {
            frameDuration = [delayTimeProp floatValue];
        }
    }
    
    // Many annoying ads specify a 0 duration to make an image flash as quickly as possible.
    // We follow Firefox's behavior and use a duration of 100 ms for any frames that specify
    // a duration of <= 10 ms. See <rdar://problem/7689300> and <http://webkit.org/b/36082>
    // for more information.
    
    if (frameDuration < 0.011f) {
        frameDuration = 0.100f;
    }
    
    CFRelease(cfFrameProperties);
    return frameDuration;
}

- (UIImage *)decompressedImageWithImage:(UIImage *)image
                                   data:(NSData *__autoreleasing  _Nullable *)data
                                options:(nullable NSDictionary<NSString*, NSObject*>*)optionsDict {
    // GIF do not decompress
    return image;
}

#pragma mark - Encode
- (BOOL)canEncodeToFormat:(YSCImageFormat)format {
    return (format == YSCImageFormatGIF);
}

- (NSData *)encodedDataWithImage:(UIImage *)image format:(YSCImageFormat)format {
    if (!image) {
        return nil;
    }
    
    if (format != YSCImageFormatGIF) {
        return nil;
    }
    
    NSMutableData *imageData = [NSMutableData data];
    CFStringRef imageUTType = [NSData YSC_UTTypeFromYSCImageFormat:YSCImageFormatGIF];
    NSArray<YSCWebImageFrame *> *frames = [YSCWebImageCoderHelper framesFromAnimatedImage:image];
    
    // Create an image destination. GIF does not support EXIF image orientation
    CGImageDestinationRef imageDestination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imageData, imageUTType, frames.count, NULL);
    if (!imageDestination) {
        // Handle failure.
        return nil;
    }
    if (frames.count == 0) {
        // for static single GIF images
        CGImageDestinationAddImage(imageDestination, image.CGImage, nil);
    } else {
        // for animated GIF images
        NSUInteger loopCount = image.YSC_imageLoopCount;
        NSDictionary *gifProperties = @{(__bridge_transfer NSString *)kCGImagePropertyGIFDictionary: @{(__bridge_transfer NSString *)kCGImagePropertyGIFLoopCount : @(loopCount)}};
        CGImageDestinationSetProperties(imageDestination, (__bridge CFDictionaryRef)gifProperties);
        
        for (size_t i = 0; i < frames.count; i++) {
            YSCWebImageFrame *frame = frames[i];
            float frameDuration = frame.duration;
            CGImageRef frameImageRef = frame.image.CGImage;
            NSDictionary *frameProperties = @{(__bridge_transfer NSString *)kCGImagePropertyGIFDictionary : @{(__bridge_transfer NSString *)kCGImagePropertyGIFUnclampedDelayTime : @(frameDuration)}};
            CGImageDestinationAddImage(imageDestination, frameImageRef, (__bridge CFDictionaryRef)frameProperties);
        }
    }
    // Finalize the destination.
    if (CGImageDestinationFinalize(imageDestination) == NO) {
        // Handle failure.
        imageData = nil;
    }
    
    CFRelease(imageDestination);
    
    return [imageData copy];
}

@end
