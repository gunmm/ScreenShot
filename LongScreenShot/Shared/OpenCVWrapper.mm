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
    
    // Separate Margins
    // Top Margin: Keep small (5%) to detect overlap even if scroll is large.
    int topMargin = (int)(H1 * 0.05); 
    if (topMargin < 50) topMargin = 50;
    
    // Bottom Margin: Set to 12% to avoid Tab Bars (usually ~10%) but keep small overlaps.
    // 20% was too aggressive and caused missed matches (Img3->4).
    int bottomMargin = (int)(H1 * 0.12);
    if (bottomMargin < 100) bottomMargin = 100; // Ensure at least 100px (approx 30-50pt) excluded
    
    // Img1: Bottom part, but exclude Bottom Margin (Footer)
    // We want the search region to be "Content".
    // Previously roi1_y = H1/2.
    int roi1_y = H1/2;
    int roi1_h = (H1 - bottomMargin) - roi1_y;
    if (roi1_h < 100) { roi1_h = H1/2; roi1_y = (H1 - bottomMargin) - roi1_h; } // Ensure we have a strip
    
    // Img2: Top part. Start from Top Margin to ignore Header.
    int roi2_y = topMargin;
    int roi2_h = (H2 - bottomMargin) - roi2_y; // Search until bottom margin of Img2 as well
    if (roi2_h < 100) { roi2_y = 0; roi2_h = H2; } 
    
    cv::Rect roi1_rect(0, roi1_y, gray1.cols, roi1_h);
    cv::Rect roi2_rect(0, roi2_y, gray2.cols, roi2_h);
    
    // Ensure ROIs are within bounds (Safety)
    roi1_rect = roi1_rect & cv::Rect(0, 0, gray1.cols, gray1.rows);
    roi2_rect = roi2_rect & cv::Rect(0, 0, gray2.cols, gray2.rows);

    cv::Mat roi1 = gray1(roi1_rect);
    cv::Mat roi2 = gray2(roi2_rect);
    
    std::vector<cv::KeyPoint> keypoints1, keypoints2;
    cv::Mat descriptors1, descriptors2;
    
    cv::Ptr<cv::ORB> orb = cv::ORB::create(1000);
    orb->detectAndCompute(roi1, cv::noArray(), keypoints1, descriptors1);
    orb->detectAndCompute(roi2, cv::noArray(), keypoints2, descriptors2);
    
    double confidence = 0.0;
    double bestShift = 0.0;
    double bestMinMatchY2 = 0.0;
    bool orbSuccess = false;

    // 3. Match
    if (!descriptors1.empty() && !descriptors2.empty()) {
        cv::BFMatcher matcher(cv::NORM_HAMMING, true);
        std::vector<cv::DMatch> matches;
        matcher.match(descriptors1, descriptors2, matches);
        
        // 4. Filter & Find Shift
        std::vector<double> validShifts;
        std::vector<cv::DMatch> goodMatches; 
        
        for (const auto& m : matches) {
            cv::Point2f pt1 = keypoints1[m.queryIdx].pt;
            cv::Point2f pt2 = keypoints2[m.trainIdx].pt;
            
            float globalY1 = pt1.y + roi1_y;
            float globalY2 = pt2.y + roi2_y;
            
            if (fabs(pt1.x - pt2.x) > 20.0) {
                continue;
            }
            
            double shift = globalY1 - globalY2;
            validShifts.push_back(shift);
            goodMatches.push_back(m);
        }
        
        if (validShifts.size() >= 5) {
            std::vector<double> sortedShifts = validShifts;
            std::sort(sortedShifts.begin(), sortedShifts.end());
            double medianShift = sortedShifts[sortedShifts.size() / 2];
            
            int consistentCount = 0;
            double minMatchY2 = 100000.0;
            
            for (size_t i = 0; i < validShifts.size(); i++) {
                double s = validShifts[i];
                if (fabs(s - medianShift) < 10.0) {
                    consistentCount++;
                    cv::Point2f pt2 = keypoints2[goodMatches[i].trainIdx].pt;
                    double globalPt2Y = pt2.y + roi2_y;
                    if (globalPt2Y < minMatchY2) minMatchY2 = globalPt2Y;
                }
            }
            
            confidence = (double)consistentCount / (double)validShifts.size();
            bestShift = medianShift;
            bestMinMatchY2 = minMatchY2;
            
            if (confidence > 0.4) {
                 orbSuccess = true;
            }
        }
    }
    
    // --- FALLBACK: TEMPLATE MATCHING ---
    if (!orbSuccess) {
        printf("OpenCV: ORB failed (Conf=%.2f). Assessing Template Matching...\n", confidence);
        
        int tplH = 200;
        if (tplH > roi1.rows) tplH = roi1.rows;
        
        // Use bottom strip of Img1 (roi1)
        // roi1 ends at H1 - bottomMargin. So this is safe from footer.
        cv::Rect tplRect(0, roi1.rows - tplH, roi1.cols, tplH);
        cv::Mat tpl = roi1(tplRect);
        
        // Check bounds
        if (tpl.rows > 0 && tpl.cols > 0 && roi2.rows >= tpl.rows && roi2.cols >= tpl.cols) {
             cv::Mat result;
             cv::matchTemplate(roi2, tpl, result, cv::TM_CCOEFF_NORMED);
             
             double minVal, maxVal;
             cv::Point minLoc, maxLoc;
             cv::minMaxLoc(result, &minVal, &maxVal, &minLoc, &maxLoc);
             
             if (maxVal > 0.55) {
                 double tplGlobalY1 = roi1_y + (roi1.rows - tplH);
                 double matchGlobalY2 = roi2_y + maxLoc.y;
                 double shift = tplGlobalY1 - matchGlobalY2;
                 
                 // Fix for MinMatchY2 (Cut Point in Img2):
                 // The cut point should be where the match IS in Img2.
                 // This ensures we switch from Img1 to Img2 at the matched feature.
                 // Since the template is from the Bottom of Img1 (above margin),
                 // we are effectively keeping the Overlap in Img1 and identifying
                 // where that Overlap *ends* in Img2 (conceptually).
                 // Actually, 'matchGlobalY2' is the Start of the Template in Img2.
                 // So we cut Img2 at the start of the template match.
                 // We keep Img1 up to the start of the template match (plus shift).
                 // This is safe because the template is guaranteed to be above the bottom margin.
                 
                 double calculatedMinMatchY2 = matchGlobalY2;
                 
                 // If Shift is calculated correctly, this point matches perfectly.
                 
                 if (calculatedMinMatchY2 < 0) calculatedMinMatchY2 = 0;
                 
                 printf("OpenCV: Template Match Success! Conf=%.2f, Shift=%.2f\n", maxVal, shift);
                 
                 bestShift = shift;
                 confidence = maxVal;
                 bestMinMatchY2 = calculatedMinMatchY2;
             }
        }
    }

    if (bestMinMatchY2 > H2) bestMinMatchY2 = 0; // Safety
    
    printf("OpenCV: Final Conf=%.2f, MedianShift=%.2f, MinMatchYInImg2=%.2f\n", confidence, bestShift, bestMinMatchY2);
    
    return @{
        @"offsetY": @((int)bestShift),
        @"confidence": @(confidence),
        @"matchYInImg2": @((int)bestMinMatchY2)
    };
}

// Helper to get cv::Mat from CVPixelBuffer (Gray only)
static void CVPixelBufferToMatGray(CVPixelBufferRef pixelBuffer, cv::Mat &outMat) {
    CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    
    int width = (int)CVPixelBufferGetWidth(pixelBuffer);
    int height = (int)CVPixelBufferGetHeight(pixelBuffer);
    
    if (CVPixelBufferGetPlaneCount(pixelBuffer) > 0) {
        // Planar YUV: Use Plane 0 (Y)
        void *base = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
        size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
        // Create Mat header, no copy yet
        cv::Mat mat(height, width, CV_8UC1, base, bytesPerRow);
        // Clone effectively copies data so we can unlock buffer independently
        mat.copyTo(outMat);
    } else {
        // BGRA: Convert to Gray
        void *base = CVPixelBufferGetBaseAddress(pixelBuffer);
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
        cv::Mat mat(height, width, CV_8UC4, base, bytesPerRow);
        cv::cvtColor(mat, outMat, cv::COLOR_BGRA2GRAY);
    }
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
}

+ (NSDictionary *)comparePixelBuffer:(CVPixelBufferRef)buffer1 with:(CVPixelBufferRef)buffer2 staticThreshold:(double)threshold {
    if (!buffer1 || !buffer2) return @{};
    
    cv::Mat gray1, gray2;
    CVPixelBufferToMatGray(buffer1, gray1);
    CVPixelBufferToMatGray(buffer2, gray2);
    
    if (gray1.empty() || gray2.empty()) return @{};
    
    // Scale down for performance
    float scale = 1.0;
    if (gray1.cols > 500) {
        scale = 500.0 / gray1.cols;
        cv::resize(gray1, gray1, cv::Size(), scale, scale);
        cv::resize(gray2, gray2, cv::Size(), scale, scale);
    }
    
    // 0. Pre-check: Are images identical (Static)?
    // Use average pixel difference to detect static scenes.
    // If scrolling, this diff should be large.
    cv::Mat diff;
    cv::absdiff(gray1, gray2, diff);
    cv::Scalar meanDiff = cv::mean(diff); // Channel 0
    
    // Use provided threshold
    if (meanDiff[0] < threshold) {
        printf("[OpenCV] Static Frame Detected (MeanDiff=%.2f < %.2f)\n", meanDiff[0], threshold);
        // Return 0 shift, 0 confidence -> Will be dropped by SampleHandler
        return @{ 
            @"dy": @(0), 
            @"confidence": @(0),
            @"meanDiff": @(meanDiff[0])
        };
    }
    
    int H1 = gray1.rows;
    // We only care about vertical shift.
    // Img1 is Previous, Img2 is Current.
    // If scrolling down, content moves UP.
    // So Img1 Bottom matches Img2 Top.
    
    // Let's use ORB features on the relevant parts
    // ROI: Bottom half of Img1, Top half of Img2
    // FIX: Exclude bottom 15% of Img1 to avoid matching static footers/tab bars
    int bottomMargin = (int)(H1 * 0.15);
    int roiHeight = (H1 / 2) - bottomMargin;
    if (roiHeight < 100) roiHeight = 100; // Safety minimum height
    
    cv::Rect roi1_rect(0, H1/2, gray1.cols, roiHeight);
    // Search in the WHOLE current frame.
    // Because if scroll is small, the content from Bottom Prev might be at Bottom Current.
    cv::Rect roi2_rect(0, 0, gray2.cols, gray2.rows);
    
    // Ensure ROIs are valid
    if (roi1_rect.y + roi1_rect.height > gray1.rows) roi1_rect.height = gray1.rows - roi1_rect.y;
    if (roi2_rect.y + roi2_rect.height > gray2.rows) roi2_rect.height = gray2.rows - roi2_rect.y;
    
    cv::Mat roi1 = gray1(roi1_rect);
    cv::Mat roi2 = gray2(roi2_rect);
    
    std::vector<cv::KeyPoint> kp1, kp2;
    cv::Mat desc1, desc2;
    cv::Ptr<cv::ORB> orb = cv::ORB::create(500); // Fewer features
    
    orb->detectAndCompute(roi1, cv::noArray(), kp1, desc1);
    orb->detectAndCompute(roi2, cv::noArray(), kp2, desc2);
    
    if (desc1.empty() || desc2.empty()) {
        return @{ @"dy": @(0), @"confidence": @(0), @"meanDiff": @(meanDiff[0]) };
    }
    
    cv::BFMatcher matcher(cv::NORM_HAMMING, true);
    std::vector<cv::DMatch> matches;
    matcher.match(desc1, desc2, matches);
    
    std::vector<double> validShifts;
    
    for (const auto& m : matches) {
        cv::Point2f pt1 = kp1[m.queryIdx].pt;
        cv::Point2f pt2 = kp2[m.trainIdx].pt;
        
        // Restore global Y coords
        float globalY1 = pt1.y + H1/2.0f;
        float globalY2 = pt2.y;
        
        // X must be roughly same (only vertical scroll)
        if (fabs(pt1.x - pt2.x) > 20.0 * scale) continue;
        
        // Shift = OldY - NewY
        // If content moved UP by 100px:
        // Feature at Y=500 in Old is now at Y=400 in New.
        // Shift = 500 - 400 = 100 (Positive).
        double shift = globalY1 - globalY2;
        validShifts.push_back(shift);
    }
    
    if (validShifts.size() < 5) {
        return @{ @"dy": @(0), @"confidence": @(0), @"meanDiff": @(meanDiff[0]) };
    }
    
    std::sort(validShifts.begin(), validShifts.end());
    double medianShift = validShifts[validShifts.size() / 2];
    
    // Scale back the shift
    double realShift = medianShift / scale;
    
    // Confidence calculation
    int consistentCount = 0;
    for (double s : validShifts) {
        if (fabs(s - medianShift) < 5.0) consistentCount++;
    }
    double confidence = (double)consistentCount / (double)validShifts.size();
    
    printf("[OpenCV] Shift=%.1f, Conf=%.2f, MeanDiff=%.2f\n", realShift, confidence, meanDiff[0]);
    
    return @{
        @"dy": @(realShift),
        @"confidence": @(confidence),
        @"meanDiff": @(meanDiff[0])
    };
}

@end
