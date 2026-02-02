#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenCVWrapper : NSObject

// 计算两张图片的重叠区域
// 返回一个字典，包含:
// "offsetY": 重叠区域在上一张图的 Y 坐标 (int)
// "overlapHeight": 重叠区域的高度 (int)
// "confidence": 匹配的置信度 (double)
+ (NSDictionary *)findOverlapBetween:(UIImage *)image1 and:(UIImage *)image2;

// Compare two CVPixelBuffers and return the vertical shift (dy).
// Returns a dictionary with "dy" (int), "confidence" (double), and "meanDiff" (double).
// dy > 0 means buffer2 is shifted DOWN relative to buffer1 (content moved UP).
// staticThreshold: Mean pixel difference below this value will be considered static.
+ (NSDictionary *)comparePixelBuffer:(CVPixelBufferRef)buffer1 with:(CVPixelBufferRef)buffer2 staticThreshold:(double)threshold;

@end

NS_ASSUME_NONNULL_END
