/*
 * This file is part of the YSCWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "MKAnnotationView+YSCWebCache.h"

#if YSC_UIKIT || YSC_MAC

#import "objc/runtime.h"
#import "UIView+YSCWebCacheOperation.h"
#import "UIView+YSCWebCache.h"

@implementation MKAnnotationView (YSCWebCache)

- (void)YSC_setImageWithURL:(nullable NSURL *)url {
    [self YSC_setImageWithURL:url placeholderImage:nil options:0 completed:nil];
}

- (void)YSC_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder {
    [self YSC_setImageWithURL:url placeholderImage:placeholder options:0 completed:nil];
}

- (void)YSC_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(YSCWebImageOptions)options {
    [self YSC_setImageWithURL:url placeholderImage:placeholder options:options completed:nil];
}

- (void)YSC_setImageWithURL:(nullable NSURL *)url completed:(nullable YSCExternalCompletionBlock)completedBlock {
    [self YSC_setImageWithURL:url placeholderImage:nil options:0 completed:completedBlock];
}

- (void)YSC_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder completed:(nullable YSCExternalCompletionBlock)completedBlock {
    [self YSC_setImageWithURL:url placeholderImage:placeholder options:0 completed:completedBlock];
}

- (void)YSC_setImageWithURL:(nullable NSURL *)url
          placeholderImage:(nullable UIImage *)placeholder
                   options:(YSCWebImageOptions)options
                 completed:(nullable YSCExternalCompletionBlock)completedBlock {
    __weak typeof(self)weakSelf = self;
    [self YSC_internalSetImageWithURL:url
                    placeholderImage:placeholder
                             options:options
                        operationKey:nil
                       setImageBlock:^(UIImage *image, NSData *imageData) {
                           weakSelf.image = image;
                       }
                            progress:nil
                           completed:completedBlock];
}

@end

#endif
