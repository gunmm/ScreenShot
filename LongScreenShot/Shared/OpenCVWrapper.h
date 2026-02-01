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

@end

NS_ASSUME_NONNULL_END
