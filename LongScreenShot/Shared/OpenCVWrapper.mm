#import "OpenCVWrapper.h"
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/features2d.hpp>

@implementation OpenCVWrapper

+ (NSDictionary *)findOverlapBetween:(UIImage *)image1 and:(UIImage *)image2 {
    if (!image1 || !image2) {
        return @{};
    }

    // 1. Convert UIImage to cv::Mat
    cv::Mat mat1, mat2;
    UIImageToMat(image1, mat1);
    UIImageToMat(image2, mat2);

    if (mat1.empty() || mat2.empty()) {
        return @{};
    }

    // Convert to grayscale
    cv::Mat gray1, gray2;
    cv::cvtColor(mat1, gray1, cv::COLOR_RGBA2GRAY);
    cv::cvtColor(mat2, gray2, cv::COLOR_RGBA2GRAY);
    
    // 2. ORB Feature Detection
    int H1 = gray1.rows;
    int H2 = gray2.rows;
    
    // Img1: Bottom 50%
    // Img2: Top 50%
    cv::Rect roi1_rect(0, H1/2, gray1.cols, H1/2);
    cv::Rect roi2_rect(0, 0, gray2.cols, H2/2);
    
    cv::Mat roi1 = gray1(roi1_rect);
    cv::Mat roi2 = gray2(roi2_rect);
    
    std::vector<cv::KeyPoint> keypoints1, keypoints2;
    cv::Mat descriptors1, descriptors2;
    
    cv::Ptr<cv::ORB> orb = cv::ORB::create(1000);
    orb->detectAndCompute(roi1, cv::noArray(), keypoints1, descriptors1);
    orb->detectAndCompute(roi2, cv::noArray(), keypoints2, descriptors2);
    
    if (descriptors1.empty() || descriptors2.empty()) {
        return @{};
    }
    
    // 3. Match
    cv::BFMatcher matcher(cv::NORM_HAMMING, true);
    std::vector<cv::DMatch> matches;
    matcher.match(descriptors1, descriptors2, matches);
    
    // 4. Filter & Find Shift
    std::vector<double> validShifts;
    std::vector<cv::DMatch> goodMatches; // Store good matches to find bounds
    
    for (const auto& m : matches) {
        cv::Point2f pt1 = keypoints1[m.queryIdx].pt;
        cv::Point2f pt2 = keypoints2[m.trainIdx].pt;
        
        float globalY1 = pt1.y + H1/2.0f;
        float globalY2 = pt2.y;
        
        if (fabs(pt1.x - pt2.x) > 20.0) {
            continue;
        }
        
        double shift = globalY1 - globalY2;
        validShifts.push_back(shift);
        goodMatches.push_back(m);
    }
    
    if (validShifts.size() < 5) {
        return @{};
    }
    
    // Median Shift
    std::vector<double> sortedShifts = validShifts;
    std::sort(sortedShifts.begin(), sortedShifts.end());
    double medianShift = sortedShifts[sortedShifts.size() / 2];
    
    // 5. Calculate Confidence and Bounds based on Consistent Matches
    int consistentCount = 0;
    double minMatchY2 = 100000.0;
    double maxMatchY2 = -1.0;
    
    for (size_t i = 0; i < validShifts.size(); i++) {
        double s = validShifts[i];
        if (fabs(s - medianShift) < 10.0) {
            consistentCount++;
            
            // Get the Y coordinate in Img2 for this match
            cv::Point2f pt2 = keypoints2[goodMatches[i].trainIdx].pt;
            if (pt2.y < minMatchY2) minMatchY2 = pt2.y;
            if (pt2.y > maxMatchY2) maxMatchY2 = pt2.y;
        }
    }
    
    double confidence = (double)consistentCount / (double)validShifts.size();
    
    if (minMatchY2 > H2) minMatchY2 = 0; // Safety
    
    printf("OpenCV: Conf=%.2f, MedianShift=%.2f, MinMatchYInImg2=%.2f\n", confidence, medianShift, minMatchY2);
    
    return @{
        @"offsetY": @((int)medianShift),
        @"confidence": @(confidence),
        @"matchYInImg2": @((int)minMatchY2) // Return the start of matching content in Img2
    };
}

@end
