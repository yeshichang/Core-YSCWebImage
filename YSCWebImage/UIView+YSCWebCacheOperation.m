/*
 * This file is part of the YSCWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIView+YSCWebCacheOperation.h"

#if YSC_UIKIT || YSC_MAC

#import "objc/runtime.h"

static char loadOperationKey;

// key is copy, value is weak because operation instance is retained by YSCWebImageManager's runningOperations property
// we should use lock to keep thread-safe because these method may not be acessed from main queue
typedef NSMapTable<NSString *, id<YSCWebImageOperation>> YSCOperationsDictionary;

@implementation UIView (YSCWebCacheOperation)

- (YSCOperationsDictionary *)YSC_operationDictionary {
    @synchronized(self) {
        YSCOperationsDictionary *operations = objc_getAssociatedObject(self, &loadOperationKey);
        if (operations) {
            return operations;
        }
        operations = [[NSMapTable alloc] initWithKeyOptions:NSMapTableCopyIn valueOptions:NSMapTableWeakMemory capacity:0];
        objc_setAssociatedObject(self, &loadOperationKey, operations, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return operations;
    }
}

- (void)YSC_setImageLoadOperation:(nullable id<YSCWebImageOperation>)operation forKey:(nullable NSString *)key {
    if (key) {
        [self YSC_cancelImageLoadOperationWithKey:key];
        if (operation) {
            YSCOperationsDictionary *operationDictionary = [self YSC_operationDictionary];
            @synchronized (self) {
                [operationDictionary setObject:operation forKey:key];
            }
        }
    }
}

- (void)YSC_cancelImageLoadOperationWithKey:(nullable NSString *)key {
    // Cancel in progress downloader from queue
    YSCOperationsDictionary *operationDictionary = [self YSC_operationDictionary];
    id<YSCWebImageOperation> operation;
    @synchronized (self) {
        operation = [operationDictionary objectForKey:key];
    }
    if (operation) {
        if ([operation conformsToProtocol:@protocol(YSCWebImageOperation)]){
            [operation cancel];
        }
        @synchronized (self) {
            [operationDictionary removeObjectForKey:key];
        }
    }
}

- (void)YSC_removeImageLoadOperationWithKey:(nullable NSString *)key {
    if (key) {
        YSCOperationsDictionary *operationDictionary = [self YSC_operationDictionary];
        @synchronized (self) {
            [operationDictionary removeObjectForKey:key];
        }
    }
}

@end

#endif
