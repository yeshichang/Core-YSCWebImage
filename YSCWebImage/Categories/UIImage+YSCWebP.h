/*
 * This file is part of the YSCWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#ifdef YSC_WEBP

#import "YSCWebImageCompat.h"

@interface UIImage (YSCWebP)

/**
 * Get the current WebP image loop count, the default value is 0.
 * For static WebP image, the value is 0.
 * For animated WebP image, 0 means repeat the animation indefinitely.
 * Note that because of the limitations of categories this property can get out of sync
 * if you create another instance with CGImage or other methods.
 * @return WebP image loop count
 * @deprecated use `YSC_imageLoopCount` instead.
 */
- (NSInteger)YSC_webpLoopCount __deprecated_msg("Method deprecated. Use `YSC_imageLoopCount` in `UIImage+MultiFormat.h`");

+ (nullable UIImage *)YSC_imageWithWebPData:(nullable NSData *)data;

@end

#endif
