/*
 * This file is part of the YSCWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Fabrice Aneche
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "NSData+YSCImageContentType.h"
#if YSC_MAC
#import <CoreServices/CoreServices.h>
#else
#import <MobileCoreServices/MobileCoreServices.h>
#endif

// Currently Image/IO does not support WebP
#define kYSCUTTypeWebP ((__bridge CFStringRef)@"public.webp")
// AVFileTypeHEIC is defined in AVFoundation via iOS 11, we use this without import AVFoundation
#define kYSCUTTypeHEIC ((__bridge CFStringRef)@"public.heic")

@implementation NSData (YSCImageContentType)

+ (YSCImageFormat)YSC_imageFormatForImageData:(nullable NSData *)data {
    if (!data) {
        return YSCImageFormatUndefined;
    }
    
    // File signatures table: http://www.garykessler.net/library/file_sigs.html
    uint8_t c;
    [data getBytes:&c length:1];
    switch (c) {
        case 0xFF:
            return YSCImageFormatJPEG;
        case 0x89:
            return YSCImageFormatPNG;
        case 0x47:
            return YSCImageFormatGIF;
        case 0x49:
        case 0x4D:
            return YSCImageFormatTIFF;
        case 0x52: {
            if (data.length >= 12) {
                //RIFF....WEBP
                NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, 12)] encoding:NSASCIIStringEncoding];
                if ([testString hasPrefix:@"RIFF"] && [testString hasSuffix:@"WEBP"]) {
                    return YSCImageFormatWebP;
                }
            }
            break;
        }
        case 0x00: {
            if (data.length >= 12) {
                //....ftypheic ....ftypheix ....ftyphevc ....ftyphevx
                NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(4, 8)] encoding:NSASCIIStringEncoding];
                if ([testString isEqualToString:@"ftypheic"]
                    || [testString isEqualToString:@"ftypheix"]
                    || [testString isEqualToString:@"ftyphevc"]
                    || [testString isEqualToString:@"ftyphevx"]) {
                    return YSCImageFormatHEIC;
                }
            }
            break;
        }
    }
    return YSCImageFormatUndefined;
}

+ (nonnull CFStringRef)YSC_UTTypeFromYSCImageFormat:(YSCImageFormat)format {
    CFStringRef UTType;
    switch (format) {
        case YSCImageFormatJPEG:
            UTType = kUTTypeJPEG;
            break;
        case YSCImageFormatPNG:
            UTType = kUTTypePNG;
            break;
        case YSCImageFormatGIF:
            UTType = kUTTypeGIF;
            break;
        case YSCImageFormatTIFF:
            UTType = kUTTypeTIFF;
            break;
        case YSCImageFormatWebP:
            UTType = kYSCUTTypeWebP;
            break;
        case YSCImageFormatHEIC:
            UTType = kYSCUTTypeHEIC;
            break;
        default:
            // default is kUTTypePNG
            UTType = kUTTypePNG;
            break;
    }
    return UTType;
}

@end
