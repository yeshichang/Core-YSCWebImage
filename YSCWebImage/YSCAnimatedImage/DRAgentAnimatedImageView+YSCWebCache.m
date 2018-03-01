//
//  DRAgentAnimatedImage+YSCWebCache.m
//  DRAgentSDK
//
//  Created by mac on 2018/2/28.
//  Copyright © 2018年 DRAgentSDK. All rights reserved.
//

#import "DRAgentAnimatedImageView+YSCWebCache.h"

#if YSC_UIKIT
#import "objc/runtime.h"
#import "UIView+YSCWebCacheOperation.h"
#import "UIView+YSCWebCache.h"
#import "NSData+YSCImageContentType.h"
#import "UIImageView+YSCWebCache.h"

#import "DRAgentAnimatedImage.h"

@implementation UIImage (DRAgentAnimatedImage)

- (DRAgentAnimatedImage *)YSC_DRAgentAnimatedImage {
    return objc_getAssociatedObject(self, @selector(YSC_DRAgentAnimatedImage));
}

- (void)setYSC_DRAgentAnimatedImage:(DRAgentAnimatedImage *)YSC_DRAgentAnimatedImage {
    objc_setAssociatedObject(self, @selector(YSC_DRAgentAnimatedImage), YSC_DRAgentAnimatedImage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation DRAgentAnimatedImageView (YSCWebCache)

- (void)YSC_setImageWithURL:(nullable NSURL *)url {
    [self YSC_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:nil];
}

- (void)YSC_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder {
    [self YSC_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:nil];
}

- (void)YSC_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(YSCWebImageOptions)options {
    [self YSC_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:nil];
}

- (void)YSC_setImageWithURL:(nullable NSURL *)url completed:(nullable YSCExternalCompletionBlock)completedBlock {
    [self YSC_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:completedBlock];
}

- (void)YSC_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder completed:(nullable YSCExternalCompletionBlock)completedBlock {
    [self YSC_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:completedBlock];
}

- (void)YSC_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(YSCWebImageOptions)options completed:(nullable YSCExternalCompletionBlock)completedBlock {
    [self YSC_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:completedBlock];
}

- (void)YSC_setImageWithURL:(nullable NSURL *)url
          placeholderImage:(nullable UIImage *)placeholder
                   options:(YSCWebImageOptions)options
                  progress:(nullable YSCWebImageDownloaderProgressBlock)progressBlock
                 completed:(nullable YSCExternalCompletionBlock)completedBlock {
    dispatch_group_t group = dispatch_group_create();
    __weak typeof(self)weakSelf = self;
    [self YSC_internalSetImageWithURL:url
                    placeholderImage:placeholder
                             options:options
                        operationKey:nil
                       setImageBlock:^(UIImage *image, NSData *imageData) {
                           // We could not directlly create the animated image on bacakground queue because it's time consuming, by the time we set it back, the current runloop has passed and the placeholder has been rendered and then replaced with animated image, this cause a flashing.
                           // Previously we use a trick to firstly set the static poster image, then set animated image back to avoid flashing, but this trick fail when using with custom UIView transition. Core Animation will use the current layer state to do rendering, so even we later set it back, the transition will not update. (it's recommended to use `YSCWebImageTransition` instead)
                           // So we have no choice to force store the DRAgentAnimatedImageView into memory cache using a associated object binding to UIImage instance. This consumed memory is adoptable and much smaller than `_UIAnimatedImage` for big GIF
                           DRAgentAnimatedImage *associatedAnimatedImage = image.YSC_DRAgentAnimatedImage;
                           if (associatedAnimatedImage) {
                               // Asscociated animated image exist
                               weakSelf.animatedImage = associatedAnimatedImage;
                               weakSelf.image = nil;
                               if (group) {
                                   dispatch_group_leave(group);
                               }
                           } else if ([NSData YSC_imageFormatForImageData:imageData] == YSCImageFormatGIF) {
                               // Firstly set the static poster image to avoid flashing
                               UIImage *posterImage = image.images ? image.images.firstObject : image;
                               weakSelf.image = posterImage;
                               weakSelf.animatedImage = nil;
                               // Secondly create DRAgentAnimatedImage in global queue because it's time consuming, then set it back
                               dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                                   DRAgentAnimatedImage *animatedImage = [DRAgentAnimatedImage animatedImageWithGIFData:imageData];
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       image.YSC_DRAgentAnimatedImage = animatedImage;
                                       weakSelf.animatedImage = animatedImage;
                                       weakSelf.image = nil;
                                       if (group) {
                                           dispatch_group_leave(group);
                                       }
                                   });
                               });
                           } else {
                               // Not animated image
                               weakSelf.image = image;
                               weakSelf.animatedImage = nil;
                               if (group) {
                                   dispatch_group_leave(group);
                               }
                           }
                       }
                            progress:progressBlock
                           completed:completedBlock
                             context:group ? @{YSCWebImageInternalSetImageGroupKey : group} : nil];
}

@end

#endif
