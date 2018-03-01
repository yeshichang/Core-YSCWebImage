/*
 * This file is part of the YSCWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImage+YSCForceDecode.h"
#import "YSCWebImageCodersManager.h"

@implementation UIImage (YSCForceDecode)

+ (UIImage *)decodedImageWithImage:(UIImage *)image {
    if (!image) {
        return nil;
    }
    NSData *tempData;
    return [[YSCWebImageCodersManager sharedInstance] decompressedImageWithImage:image data:&tempData options:@{YSCWebImageCoderScaleDownLargeImagesKey: @(NO)}];
}

+ (UIImage *)decodedAndScaledDownImageWithImage:(UIImage *)image {
    if (!image) {
        return nil;
    }
    NSData *tempData;
    return [[YSCWebImageCodersManager sharedInstance] decompressedImageWithImage:image data:&tempData options:@{YSCWebImageCoderScaleDownLargeImagesKey: @(YES)}];
}

@end
