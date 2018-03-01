/*
 * This file is part of the YSCWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#ifdef YSC_WEBP

#import "UIImage+WebP.h"
#import "YSCWebImageWebPCoder.h"
#import "UIImage+MultiFormat.h"

@implementation UIImage (YSCWebP)

- (NSInteger)YSC_webpLoopCount {
    return self.YSC_imageLoopCount;
}

+ (nullable UIImage *)YSC_imageWithWebPData:(nullable NSData *)data {
    if (!data) {
        return nil;
    }
    return [[YSCWebImageWebPCoder sharedCoder] decodedImageWithData:data];
}

@end

#endif
