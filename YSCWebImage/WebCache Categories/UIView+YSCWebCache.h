/*
 * This file is part of the YSCWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "YSCWebImageCompat.h"

#if YSC_UIKIT || YSC_MAC

#import "YSCWebImageManager.h"

/**
 A Dispatch group to maintain setImageBlock and completionBlock. This key should be used only internally and may be changed in the future. (dispatch_group_t)
 */
FOUNDATION_EXPORT NSString * _Nonnull const YSCWebImageInternalSetImageGroupKey;
/**
 A YSCWebImageManager instance to control the image download and cache process using in UIImageView+WebCache category and likes. If not provided, use the shared manager (YSCWebImageManager)
 */
FOUNDATION_EXPORT NSString * _Nonnull const YSCWebImageExternalCustomManagerKey;

typedef void(^YSCSetImageBlock)(UIImage * _Nullable image, NSData * _Nullable imageData);

@interface UIView (YSCWebCache)

/**
 * Get the current image URL.
 *
 * Note that because of the limitations of categories this property can get out of sync
 * if you use setImage: directly.
 */
- (nullable NSURL *)YSC_imageURL;

/**
 * Set the imageView `image` with an `url` and optionally a placeholder image.
 *
 * The download is asynchronous and cached.
 *
 * @param url            The url for the image.
 * @param placeholder    The image to be set initially, until the image request finishes.
 * @param options        The options to use when downloading the image. @see YSCWebImageOptions for the possible values.
 * @param operationKey   A string to be used as the operation key. If nil, will use the class name
 * @param setImageBlock  Block used for custom set image code
 * @param progressBlock  A block called while image is downloading
 *                       @note the progress block is executed on a background queue
 * @param completedBlock A block called when operation has been completed. This block has no return value
 *                       and takes the requested UIImage as first parameter. In case of error the image parameter
 *                       is nil and the second parameter may contain an NSError. The third parameter is a Boolean
 *                       indicating if the image was retrieved from the local cache or from the network.
 *                       The fourth parameter is the original image url.
 */
- (void)YSC_internalSetImageWithURL:(nullable NSURL *)url
                  placeholderImage:(nullable UIImage *)placeholder
                           options:(YSCWebImageOptions)options
                      operationKey:(nullable NSString *)operationKey
                     setImageBlock:(nullable YSCSetImageBlock)setImageBlock
                          progress:(nullable YSCWebImageDownloaderProgressBlock)progressBlock
                         completed:(nullable YSCExternalCompletionBlock)completedBlock;

/**
 * Set the imageView `image` with an `url` and optionally a placeholder image.
 *
 * The download is asynchronous and cached.
 *
 * @param url            The url for the image.
 * @param placeholder    The image to be set initially, until the image request finishes.
 * @param options        The options to use when downloading the image. @see YSCWebImageOptions for the possible values.
 * @param operationKey   A string to be used as the operation key. If nil, will use the class name
 * @param setImageBlock  Block used for custom set image code
 * @param progressBlock  A block called while image is downloading
 *                       @note the progress block is executed on a background queue
 * @param completedBlock A block called when operation has been completed. This block has no return value
 *                       and takes the requested UIImage as first parameter. In case of error the image parameter
 *                       is nil and the second parameter may contain an NSError. The third parameter is a Boolean
 *                       indicating if the image was retrieved from the local cache or from the network.
 *                       The fourth parameter is the original image url.
 * @param context        A context with extra information to perform specify changes or processes.
 */
- (void)YSC_internalSetImageWithURL:(nullable NSURL *)url
                  placeholderImage:(nullable UIImage *)placeholder
                           options:(YSCWebImageOptions)options
                      operationKey:(nullable NSString *)operationKey
                     setImageBlock:(nullable YSCSetImageBlock)setImageBlock
                          progress:(nullable YSCWebImageDownloaderProgressBlock)progressBlock
                         completed:(nullable YSCExternalCompletionBlock)completedBlock
                           context:(nullable NSDictionary *)context;

/**
 * Cancel the current download
 */
- (void)YSC_cancelCurrentImageLoad;

#if YSC_UIKIT

#pragma mark - Activity indicator

/**
 *  Show activity UIActivityIndicatorView
 */
- (void)YSC_setShowActivityIndicatorView:(BOOL)show;

/**
 *  set desired UIActivityIndicatorViewStyle
 *
 *  @param style The style of the UIActivityIndicatorView
 */
- (void)YSC_setIndicatorStyle:(UIActivityIndicatorViewStyle)style;

- (BOOL)YSC_showActivityIndicatorView;
- (void)YSC_addActivityIndicator;
- (void)YSC_removeActivityIndicator;

#endif

@end

#endif
