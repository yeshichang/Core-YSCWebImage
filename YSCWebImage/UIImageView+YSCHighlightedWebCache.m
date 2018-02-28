/*
 * This file is part of the YSCWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImageView+YSCHighlightedWebCache.h"

#if YSC_UIKIT

#import "UIView+YSCWebCacheOperation.h"
#import "UIView+YSCWebCache.h"

@implementation UIImageView (YSCHighlightedWebCache)

- (void)YSC_setHighlightedImageWithURL:(nullable NSURL *)url {
    [self YSC_setHighlightedImageWithURL:url options:0 progress:nil completed:nil];
}

- (void)YSC_setHighlightedImageWithURL:(nullable NSURL *)url options:(YSCWebImageOptions)options {
    [self YSC_setHighlightedImageWithURL:url options:options progress:nil completed:nil];
}

- (void)YSC_setHighlightedImageWithURL:(nullable NSURL *)url completed:(nullable YSCExternalCompletionBlock)completedBlock {
    [self YSC_setHighlightedImageWithURL:url options:0 progress:nil completed:completedBlock];
}

- (void)YSC_setHighlightedImageWithURL:(nullable NSURL *)url options:(YSCWebImageOptions)options completed:(nullable YSCExternalCompletionBlock)completedBlock {
    [self YSC_setHighlightedImageWithURL:url options:options progress:nil completed:completedBlock];
}

- (void)YSC_setHighlightedImageWithURL:(nullable NSURL *)url
                              options:(YSCWebImageOptions)options
                             progress:(nullable YSCWebImageDownloaderProgressBlock)progressBlock
                            completed:(nullable YSCExternalCompletionBlock)completedBlock {
    __weak typeof(self)weakSelf = self;
    [self YSC_internalSetImageWithURL:url
                    placeholderImage:nil
                             options:options
                        operationKey:@"UIImageViewImageOperationHighlighted"
                       setImageBlock:^(UIImage *image, NSData *imageData) {
                           weakSelf.highlightedImage = image;
                       }
                            progress:progressBlock
                           completed:completedBlock];
}

@end

#endif
