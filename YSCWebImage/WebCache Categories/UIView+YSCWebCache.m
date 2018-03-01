/*
 * This file is part of the YSCWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIView+YSCWebCache.h"

#if YSC_UIKIT || YSC_MAC

#import "objc/runtime.h"
#import "UIView+YSCWebCacheOperation.h"

NSString * const YSCWebImageInternalSetImageGroupKey = @"internalSetImageGroup";
NSString * const YSCWebImageExternalCustomManagerKey = @"externalCustomManager";

static char imageURLKey;

#if YSC_UIKIT
static char TAG_ACTIVITY_INDICATOR;
static char TAG_ACTIVITY_STYLE;
#endif
static char TAG_ACTIVITY_SHOW;

@implementation UIView (YSCWebCache)

- (nullable NSURL *)YSC_imageURL {
    return objc_getAssociatedObject(self, &imageURLKey);
}

- (void)YSC_internalSetImageWithURL:(nullable NSURL *)url
                  placeholderImage:(nullable UIImage *)placeholder
                           options:(YSCWebImageOptions)options
                      operationKey:(nullable NSString *)operationKey
                     setImageBlock:(nullable YSCSetImageBlock)setImageBlock
                          progress:(nullable YSCWebImageDownloaderProgressBlock)progressBlock
                         completed:(nullable YSCExternalCompletionBlock)completedBlock {
    return [self YSC_internalSetImageWithURL:url placeholderImage:placeholder options:options operationKey:operationKey setImageBlock:setImageBlock progress:progressBlock completed:completedBlock context:nil];
}

- (void)YSC_internalSetImageWithURL:(nullable NSURL *)url
                  placeholderImage:(nullable UIImage *)placeholder
                           options:(YSCWebImageOptions)options
                      operationKey:(nullable NSString *)operationKey
                     setImageBlock:(nullable YSCSetImageBlock)setImageBlock
                          progress:(nullable YSCWebImageDownloaderProgressBlock)progressBlock
                         completed:(nullable YSCExternalCompletionBlock)completedBlock
                           context:(nullable NSDictionary *)context {
    NSString *validOperationKey = operationKey ?: NSStringFromClass([self class]);
    [self YSC_cancelImageLoadOperationWithKey:validOperationKey];
    objc_setAssociatedObject(self, &imageURLKey, url, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (!(options & YSCWebImageDelayPlaceholder)) {
        if ([context valueForKey:YSCWebImageInternalSetImageGroupKey]) {
            dispatch_group_t group = [context valueForKey:YSCWebImageInternalSetImageGroupKey];
            dispatch_group_enter(group);
        }
        dispatch_main_async_safe(^{
            [self YSC_setImage:placeholder imageData:nil basedOnClassOrViaCustomSetImageBlock:setImageBlock];
        });
    }
    
    if (url) {
        // check if activityView is enabled or not
        if ([self YSC_showActivityIndicatorView]) {
            [self YSC_addActivityIndicator];
        }
        
        YSCWebImageManager *manager;
        if ([context valueForKey:YSCWebImageExternalCustomManagerKey]) {
            manager = (YSCWebImageManager *)[context valueForKey:YSCWebImageExternalCustomManagerKey];
        } else {
            manager = [YSCWebImageManager sharedManager];
        }
        
        __weak __typeof(self)wself = self;
        id <YSCWebImageOperation> operation = [manager loadImageWithURL:url options:options progress:progressBlock completed:^(UIImage *image, NSData *data, NSError *error, YSCImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            __strong __typeof (wself) sself = wself;
            [sself YSC_removeActivityIndicator];
            if (!sself) { return; }
            BOOL shouldCallCompletedBlock = finished || (options & YSCWebImageAvoidAutoSetImage);
            BOOL shouldNotSetImage = ((image && (options & YSCWebImageAvoidAutoSetImage)) ||
                                      (!image && !(options & YSCWebImageDelayPlaceholder)));
            YSCWebImageNoParamsBlock callCompletedBlockClojure = ^{
                if (!sself) { return; }
                if (!shouldNotSetImage) {
                    [sself YSC_setNeedsLayout];
                }
                if (completedBlock && shouldCallCompletedBlock) {
                    completedBlock(image, error, cacheType, url);
                }
            };
            
            // case 1a: we got an image, but the YSCWebImageAvoidAutoSetImage flag is set
            // OR
            // case 1b: we got no image and the YSCWebImageDelayPlaceholder is not set
            if (shouldNotSetImage) {
                dispatch_main_async_safe(callCompletedBlockClojure);
                return;
            }
            
            UIImage *targetImage = nil;
            NSData *targetData = nil;
            if (image) {
                // case 2a: we got an image and the YSCWebImageAvoidAutoSetImage is not set
                targetImage = image;
                targetData = data;
            } else if (options & YSCWebImageDelayPlaceholder) {
                // case 2b: we got no image and the YSCWebImageDelayPlaceholder flag is set
                targetImage = placeholder;
                targetData = nil;
            }
            
            if ([context valueForKey:YSCWebImageInternalSetImageGroupKey]) {
                dispatch_group_t group = [context valueForKey:YSCWebImageInternalSetImageGroupKey];
                dispatch_group_enter(group);
                dispatch_main_async_safe(^{
                    [sself YSC_setImage:targetImage imageData:targetData basedOnClassOrViaCustomSetImageBlock:setImageBlock];
                });
                // ensure completion block is called after custom setImage process finish
                dispatch_group_notify(group, dispatch_get_main_queue(), ^{
                    callCompletedBlockClojure();
                });
            } else {
                dispatch_main_async_safe(^{
                    [sself YSC_setImage:targetImage imageData:targetData basedOnClassOrViaCustomSetImageBlock:setImageBlock];
                    callCompletedBlockClojure();
                });
            }
        }];
        [self YSC_setImageLoadOperation:operation forKey:validOperationKey];
    } else {
        dispatch_main_async_safe(^{
            [self YSC_removeActivityIndicator];
            if (completedBlock) {
                NSError *error = [NSError errorWithDomain:YSCWebImageErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey : @"Trying to load a nil url"}];
                completedBlock(nil, error, YSCImageCacheTypeNone, url);
            }
        });
    }
}

- (void)YSC_cancelCurrentImageLoad {
    [self YSC_cancelImageLoadOperationWithKey:NSStringFromClass([self class])];
}

- (void)YSC_setImage:(UIImage *)image imageData:(NSData *)imageData basedOnClassOrViaCustomSetImageBlock:(YSCSetImageBlock)setImageBlock {
    if (setImageBlock) {
        setImageBlock(image, imageData);
        return;
    }
    
#if YSC_UIKIT || YSC_MAC
    if ([self isKindOfClass:[UIImageView class]]) {
        UIImageView *imageView = (UIImageView *)self;
        imageView.image = image;
    }
#endif
    
#if YSC_UIKIT
    if ([self isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)self;
        [button setImage:image forState:UIControlStateNormal];
    }
#endif
}

- (void)YSC_setNeedsLayout {
#if YSC_UIKIT
    [self setNeedsLayout];
#elif YSC_MAC
    [self setNeedsLayout:YES];
#endif
}

#pragma mark - Activity indicator

#pragma mark -
#if YSC_UIKIT
- (UIActivityIndicatorView *)activityIndicator {
    return (UIActivityIndicatorView *)objc_getAssociatedObject(self, &TAG_ACTIVITY_INDICATOR);
}

- (void)setActivityIndicator:(UIActivityIndicatorView *)activityIndicator {
    objc_setAssociatedObject(self, &TAG_ACTIVITY_INDICATOR, activityIndicator, OBJC_ASSOCIATION_RETAIN);
}
#endif

- (void)YSC_setShowActivityIndicatorView:(BOOL)show {
    objc_setAssociatedObject(self, &TAG_ACTIVITY_SHOW, @(show), OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)YSC_showActivityIndicatorView {
    return [objc_getAssociatedObject(self, &TAG_ACTIVITY_SHOW) boolValue];
}

#if YSC_UIKIT
- (void)YSC_setIndicatorStyle:(UIActivityIndicatorViewStyle)style{
    objc_setAssociatedObject(self, &TAG_ACTIVITY_STYLE, [NSNumber numberWithInt:style], OBJC_ASSOCIATION_RETAIN);
}

- (int)YSC_getIndicatorStyle{
    return [objc_getAssociatedObject(self, &TAG_ACTIVITY_STYLE) intValue];
}
#endif

- (void)YSC_addActivityIndicator {
#if YSC_UIKIT
    dispatch_main_async_safe(^{
        if (!self.activityIndicator) {
            self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[self YSC_getIndicatorStyle]];
            self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
        
            [self addSubview:self.activityIndicator];
            
            [self addConstraint:[NSLayoutConstraint constraintWithItem:self.activityIndicator
                                                             attribute:NSLayoutAttributeCenterX
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self
                                                             attribute:NSLayoutAttributeCenterX
                                                            multiplier:1.0
                                                              constant:0.0]];
            [self addConstraint:[NSLayoutConstraint constraintWithItem:self.activityIndicator
                                                             attribute:NSLayoutAttributeCenterY
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self
                                                             attribute:NSLayoutAttributeCenterY
                                                            multiplier:1.0
                                                              constant:0.0]];
        }
        [self.activityIndicator startAnimating];
    });
#endif
}

- (void)YSC_removeActivityIndicator {
#if YSC_UIKIT
    dispatch_main_async_safe(^{
        if (self.activityIndicator) {
            [self.activityIndicator removeFromSuperview];
            self.activityIndicator = nil;
        }
    });
#endif
}

@end

#endif
