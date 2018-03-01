/*
 * This file is part of the YSCWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Fabrice Aneche
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "YSCWebImageCompat.h"

typedef NS_ENUM(NSInteger, YSCImageFormat) {
    YSCImageFormatUndefined = -1,
    YSCImageFormatJPEG = 0,
    YSCImageFormatPNG,
    YSCImageFormatGIF,
    YSCImageFormatTIFF,
    YSCImageFormatWebP,
    YSCImageFormatHEIC
};

@interface NSData (YSCImageContentType)

/**
 *  Return image format
 *
 *  @param data the input image data
 *
 *  @return the image format as `YSCImageFormat` (enum)
 */
+ (YSCImageFormat)YSC_imageFormatForImageData:(nullable NSData *)data;

/**
 Convert YSCImageFormat to UTType

 @param format Format as YSCImageFormat
 @return The UTType as CFStringRef
 */
+ (nonnull CFStringRef)YSC_UTTypeFromYSCImageFormat:(YSCImageFormat)format;

@end
