/*
 * This file is part of the YSCWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIButton+YSCWebCache.h"

#if YSC_UIKIT

#import "objc/runtime.h"
#import "UIView+YSCWebCacheOperation.h"
#import "UIView+YSCWebCache.h"

static char imageURLStorageKey;

typedef NSMutableDictionary<NSString *, NSURL *> YSCStateImageURLDictionary;

static inline NSString * imageURLKeyForState(UIControlState state) {
    return [NSString stringWithFormat:@"image_%lu", (unsigned long)state];
}

static inline NSString * backgroundImageURLKeyForState(UIControlState state) {
    return [NSString stringWithFormat:@"backgroundImage_%lu", (unsigned long)state];
}

@implementation UIButton (YSCWebCache)

#pragma mark - Image

- (nullable NSURL *)YSC_currentImageURL {
    NSURL *url = self.imageURLStorage[imageURLKeyForState(self.state)];

    if (!url) {
        url = self.imageURLStorage[imageURLKeyForState(UIControlStateNormal)];
    }

    return url;
}

- (nullable NSURL *)YSC_imageURLForState:(UIControlState)state {
    return self.imageURLStorage[imageURLKeyForState(state)];
}

- (void)YSC_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state {
    [self YSC_setImageWithURL:url forState:state placeholderImage:nil options:0 completed:nil];
}

- (void)YSC_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder {
    [self YSC_setImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:nil];
}

- (void)YSC_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder options:(YSCWebImageOptions)options {
    [self YSC_setImageWithURL:url forState:state placeholderImage:placeholder options:options completed:nil];
}

- (void)YSC_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state completed:(nullable YSCExternalCompletionBlock)completedBlock {
    [self YSC_setImageWithURL:url forState:state placeholderImage:nil options:0 completed:completedBlock];
}

- (void)YSC_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder completed:(nullable YSCExternalCompletionBlock)completedBlock {
    [self YSC_setImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:completedBlock];
}

- (void)YSC_setImageWithURL:(nullable NSURL *)url
                  forState:(UIControlState)state
          placeholderImage:(nullable UIImage *)placeholder
                   options:(YSCWebImageOptions)options
                 completed:(nullable YSCExternalCompletionBlock)completedBlock {
    if (!url) {
        [self.imageURLStorage removeObjectForKey:imageURLKeyForState(state)];
    } else {
        self.imageURLStorage[imageURLKeyForState(state)] = url;
    }
    
    __weak typeof(self)weakSelf = self;
    [self YSC_internalSetImageWithURL:url
                    placeholderImage:placeholder
                             options:options
                        operationKey:[NSString stringWithFormat:@"UIButtonImageOperation%@", @(state)]
                       setImageBlock:^(UIImage *image, NSData *imageData) {
                           [weakSelf setImage:image forState:state];
                       }
                            progress:nil
                           completed:completedBlock];
}

#pragma mark - Background image

- (nullable NSURL *)YSC_currentBackgroundImageURL {
    NSURL *url = self.imageURLStorage[backgroundImageURLKeyForState(self.state)];
    
    if (!url) {
        url = self.imageURLStorage[backgroundImageURLKeyForState(UIControlStateNormal)];
    }
    
    return url;
}

- (nullable NSURL *)YSC_backgroundImageURLForState:(UIControlState)state {
    return self.imageURLStorage[backgroundImageURLKeyForState(state)];
}

- (void)YSC_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state {
    [self YSC_setBackgroundImageWithURL:url forState:state placeholderImage:nil options:0 completed:nil];
}

- (void)YSC_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder {
    [self YSC_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:nil];
}

- (void)YSC_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder options:(YSCWebImageOptions)options {
    [self YSC_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:options completed:nil];
}

- (void)YSC_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state completed:(nullable YSCExternalCompletionBlock)completedBlock {
    [self YSC_setBackgroundImageWithURL:url forState:state placeholderImage:nil options:0 completed:completedBlock];
}

- (void)YSC_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder completed:(nullable YSCExternalCompletionBlock)completedBlock {
    [self YSC_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:completedBlock];
}

- (void)YSC_setBackgroundImageWithURL:(nullable NSURL *)url
                            forState:(UIControlState)state
                    placeholderImage:(nullable UIImage *)placeholder
                             options:(YSCWebImageOptions)options
                           completed:(nullable YSCExternalCompletionBlock)completedBlock {
    if (!url) {
        [self.imageURLStorage removeObjectForKey:backgroundImageURLKeyForState(state)];
    } else {
        self.imageURLStorage[backgroundImageURLKeyForState(state)] = url;
    }
    
    __weak typeof(self)weakSelf = self;
    [self YSC_internalSetImageWithURL:url
                    placeholderImage:placeholder
                             options:options
                        operationKey:[NSString stringWithFormat:@"UIButtonBackgroundImageOperation%@", @(state)]
                       setImageBlock:^(UIImage *image, NSData *imageData) {
                           [weakSelf setBackgroundImage:image forState:state];
                       }
                            progress:nil
                           completed:completedBlock];
}

- (void)YSC_cancelImageLoadForState:(UIControlState)state {
    [self YSC_cancelImageLoadOperationWithKey:[NSString stringWithFormat:@"UIButtonImageOperation%@", @(state)]];
}

- (void)YSC_cancelBackgroundImageLoadForState:(UIControlState)state {
    [self YSC_cancelImageLoadOperationWithKey:[NSString stringWithFormat:@"UIButtonBackgroundImageOperation%@", @(state)]];
}

- (YSCStateImageURLDictionary *)imageURLStorage {
    YSCStateImageURLDictionary *storage = objc_getAssociatedObject(self, &imageURLStorageKey);
    if (!storage) {
        storage = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, &imageURLStorageKey, storage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    return storage;
}

@end

#endif
