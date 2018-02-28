/*
 * This file is part of the YSCWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Laurin Brandner
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImage+YSCGIF.h"
#import "YSCWebImageGIFCoder.h"
#import "NSImage+YSCWebCache.h"

@implementation UIImage (YSCGIF)

+ (UIImage *)YSC_animatedGIFWithData:(NSData *)data {
    if (!data) {
        return nil;
    }
    return [[YSCWebImageGIFCoder sharedCoder] decodedImageWithData:data];
}

- (BOOL)isGIF {
    return (self.images != nil);
}

@end
