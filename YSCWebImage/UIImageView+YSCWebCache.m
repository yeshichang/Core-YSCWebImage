/*
 * This file is part of the YSCWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImageView+YSCWebCache.h"

#if YSC_UIKIT || YSC_MAC

#import "objc/runtime.h"
#import "UIView+YSCWebCacheOperation.h"
#import "UIView+YSCWebCache.h"

@implementation UIImageView (YSCWebCache)

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
    [self YSC_internalSetImageWithURL:url
                    placeholderImage:placeholder
                             options:options
                        operationKey:nil
                       setImageBlock:nil
                            progress:progressBlock
                           completed:completedBlock];
}

- (void)YSC_setImageWithPreviousCachedImageWithURL:(nullable NSURL *)url
                                 placeholderImage:(nullable UIImage *)placeholder
                                          options:(YSCWebImageOptions)options
                                         progress:(nullable YSCWebImageDownloaderProgressBlock)progressBlock
                                        completed:(nullable YSCExternalCompletionBlock)completedBlock {
    NSString *key = [[YSCWebImageManager sharedManager] cacheKeyForURL:url];
    UIImage *lastPreviousCachedImage = [[YSCImageCache sharedImageCache] imageFromCacheForKey:key];
    
    [self YSC_setImageWithURL:url placeholderImage:lastPreviousCachedImage ?: placeholder options:options progress:progressBlock completed:completedBlock];    
}

#if YSC_UIKIT

#pragma mark - Animation of multiple images

- (void)YSC_setAnimationImagesWithURLs:(nonnull NSArray<NSURL *> *)arrayOfURLs {
    [self YSC_cancelCurrentAnimationImagesLoad];
    __weak __typeof(self)wself = self;

    NSPointerArray *operationsArray = [self YSC_animationOperationArray];

    [arrayOfURLs enumerateObjectsUsingBlock:^(NSURL *logoImageURL, NSUInteger idx, BOOL * _Nonnull stop) {
        id <YSCWebImageOperation> operation = [[YSCWebImageManager sharedManager] loadImageWithURL:logoImageURL options:0 progress:nil completed:^(UIImage *image, NSData *data, NSError *error, YSCImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            if (!wself) return;
            dispatch_main_async_safe(^{
                __strong UIImageView *sself = wself;
                [sself stopAnimating];
                if (sself && image) {
                    NSMutableArray<UIImage *> *currentImages = [[sself animationImages] mutableCopy];
                    if (!currentImages) {
                        currentImages = [[NSMutableArray alloc] init];
                    }
                    
                    // We know what index objects should be at when they are returned so
                    // we will put the object at the index, filling any empty indexes
                    // with the image that was returned too "early". These images will
                    // be overwritten. (does not require additional sorting datastructure)
                    while ([currentImages count] < idx) {
                        [currentImages addObject:image];
                    }
                    
                    currentImages[idx] = image;

                    sself.animationImages = currentImages;
                    [sself setNeedsLayout];
                }
                [sself startAnimating];
            });
        }];
        @synchronized (self) {
            [operationsArray addPointer:(__bridge void *)(operation)];
        }
    }];
}

static char animationLoadOperationKey;

// element is weak because operation instance is retained by YSCWebImageManager's runningOperations property
// we should use lock to keep thread-safe because these method may not be acessed from main queue
- (NSPointerArray *)YSC_animationOperationArray {
    @synchronized(self) {
        NSPointerArray *operationsArray = objc_getAssociatedObject(self, &animationLoadOperationKey);
        if (operationsArray) {
            return operationsArray;
        }
        operationsArray = [NSPointerArray weakObjectsPointerArray];
        objc_setAssociatedObject(self, &animationLoadOperationKey, operationsArray, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return operationsArray;
    }
}

- (void)YSC_cancelCurrentAnimationImagesLoad {
    NSPointerArray *operationsArray = [self YSC_animationOperationArray];
    if (operationsArray) {
        @synchronized (self) {
            for (id operation in operationsArray) {
                if ([operation conformsToProtocol:@protocol(YSCWebImageOperation)]) {
                    [operation cancel];
                }
            }
            operationsArray.count = 0;
        }
    }
}
#endif

@end

#endif
