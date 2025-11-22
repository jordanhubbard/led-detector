#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenCVProcessor : NSObject

- (nullable NSImage *)processImage:(CGImageRef)image;

@end

NS_ASSUME_NONNULL_END
