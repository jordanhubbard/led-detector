#import <opencv2/opencv.hpp>
#import "OpenCVProcessor.h"

@implementation OpenCVProcessor

- (NSImage *)processImage:(CGImageRef)image {
    cv::Mat mat = [self cvMatFromCGImage:image];
    cv::Mat result = mat.clone();
    
    cv::Mat gray;
    cv::cvtColor(mat, gray, cv::COLOR_BGR2GRAY);
    
    // Enhance bright spots (LEDs) - they should glow brightly
    cv::Mat enhanced;
    cv::threshold(gray, enhanced, 200, 255, cv::THRESH_TOZERO);
    cv::GaussianBlur(enhanced, enhanced, cv::Size(5, 5), 1);
    
    // Detect circles (potential LEDs) with parameters tuned for small, bright, imperfect circles
    std::vector<cv::Vec3f> circles;
    cv::HoughCircles(enhanced, circles, cv::HOUGH_GRADIENT, 1.0,
                     25,               // min distance between circles
                     60,               // Canny edge threshold
                     25,               // accumulator threshold (higher to reduce false positives)
                     5, 35);           // min/max radius (small LEDs but not tiny noise)
    
    // Process each detected circle
    for (size_t i = 0; i < circles.size(); i++) {
        cv::Point center(cvRound(circles[i][0]), cvRound(circles[i][1]));
        int radius = cvRound(circles[i][2]);
        
        // Draw prominent LED highlighting
        // Outer glow
        cv::circle(result, center, radius + 4, cv::Scalar(0, 255, 255), 1);
        cv::circle(result, center, radius + 2, cv::Scalar(0, 255, 255), 1);
        // Main circle
        cv::circle(result, center, radius, cv::Scalar(0, 255, 255), 3);
        // Center crosshair
        cv::line(result, cv::Point(center.x - 10, center.y), 
                 cv::Point(center.x + 10, center.y), cv::Scalar(0, 255, 255), 2);
        cv::line(result, cv::Point(center.x, center.y - 10), 
                 cv::Point(center.x, center.y + 10), cv::Scalar(0, 255, 255), 2);
        
        // Add LED number label if multiple LEDs
        if (circles.size() > 1) {
            char numLabel[10];
            sprintf(numLabel, "#%zu", i + 1);
            cv::putText(result, numLabel, cv::Point(center.x - 15, center.y - radius - 35),
                        cv::FONT_HERSHEY_SIMPLEX, 0.7, cv::Scalar(0, 255, 255), 2);
        }
        
        // Analyze this circle to find the flat edge (cathode)
        [self detectCathodeOrientation:gray result:result center:center radius:radius ledNum:i + 1];
    }
    
    // Add instructions overlay with semi-transparent background
    cv::rectangle(result, cv::Point(5, 5), cv::Point(450, 100), 
                  cv::Scalar(0, 0, 0), -1);
    cv::rectangle(result, cv::Point(5, 5), cv::Point(450, 100), 
                  cv::Scalar(255, 255, 0), 2);
    
    cv::putText(result, "LED Cathode Detector", cv::Point(15, 35),
                cv::FONT_HERSHEY_DUPLEX, 0.8, cv::Scalar(255, 255, 0), 2);
    
    char detectionText[100];
    sprintf(detectionText, "LEDs detected: %zu", circles.size());
    cv::putText(result, detectionText, cv::Point(15, 65),
                cv::FONT_HERSHEY_SIMPLEX, 0.6, cv::Scalar(255, 255, 255), 1);
    
    if (circles.size() == 0) {
        cv::putText(result, "Hold LED in front of camera", cv::Point(15, 90),
                    cv::FONT_HERSHEY_SIMPLEX, 0.5, cv::Scalar(200, 200, 200), 1);
    }
    
    // Add legend
    int legendY = result.rows - 120;
    cv::rectangle(result, cv::Point(5, legendY), cv::Point(280, result.rows - 5),
                  cv::Scalar(0, 0, 0), -1);
    cv::rectangle(result, cv::Point(5, legendY), cv::Point(280, result.rows - 5),
                  cv::Scalar(100, 100, 100), 1);
    
    cv::putText(result, "Legend:", cv::Point(15, legendY + 25),
                cv::FONT_HERSHEY_SIMPLEX, 0.5, cv::Scalar(255, 255, 255), 1);
    cv::circle(result, cv::Point(25, legendY + 48), 8, cv::Scalar(0, 255, 255), 2);
    cv::putText(result, "= LED detected", cv::Point(40, legendY + 52),
                cv::FONT_HERSHEY_SIMPLEX, 0.4, cv::Scalar(200, 200, 200), 1);
    cv::circle(result, cv::Point(25, legendY + 73), 3, cv::Scalar(255, 0, 255), -1);
    cv::putText(result, "= Flat edge (cathode side)", cv::Point(40, legendY + 77),
                cv::FONT_HERSHEY_SIMPLEX, 0.4, cv::Scalar(200, 200, 200), 1);
    cv::arrowedLine(result, cv::Point(15, legendY + 95), cv::Point(35, legendY + 95),
                    cv::Scalar(0, 0, 255), 2, cv::LINE_AA, 0, 0.3);
    cv::putText(result, "= Cathode direction", cv::Point(40, legendY + 100),
                cv::FONT_HERSHEY_SIMPLEX, 0.4, cv::Scalar(200, 200, 200), 1);
    
    return [self NSImageFromCVMat:result];
}

- (void)detectCathodeOrientation:(cv::Mat&)gray result:(cv::Mat&)result 
                          center:(cv::Point)center radius:(int)radius ledNum:(size_t)ledNum {
    // Extract ROI around the circle
    int roiSize = radius * 3;
    cv::Rect roi(center.x - roiSize/2, center.y - roiSize/2, roiSize, roiSize);
    
    // Bounds checking
    roi.x = std::max(0, roi.x);
    roi.y = std::max(0, roi.y);
    roi.width = std::min(gray.cols - roi.x, roi.width);
    roi.height = std::min(gray.rows - roi.y, roi.height);
    
    if (roi.width <= 0 || roi.height <= 0) return;
    
    cv::Mat roiGray = gray(roi);
    
    // Edge detection in ROI
    cv::Mat edges;
    cv::Canny(roiGray, edges, 50, 150);
    
    // Find contours
    std::vector<std::vector<cv::Point>> contours;
    cv::findContours(edges, contours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);
    
    // Find the largest contour (likely the LED outline)
    if (contours.empty()) return;
    
    size_t largestIdx = 0;
    double largestArea = 0;
    for (size_t i = 0; i < contours.size(); i++) {
        double area = cv::contourArea(contours[i]);
        if (area > largestArea) {
            largestArea = area;
            largestIdx = i;
        }
    }
    
    if (largestArea < 100) return;  // Too small
    
    std::vector<cv::Point> ledContour = contours[largestIdx];
    
    // Translate contour back to full image coordinates
    for (auto& pt : ledContour) {
        pt.x += roi.x;
        pt.y += roi.y;
    }
    
    // Find the flat edge by analyzing the contour
    // Method: Fit a circle and find points that deviate significantly
    cv::Point2f circleCenter;
    float circleRadius;
    cv::minEnclosingCircle(ledContour, circleCenter, circleRadius);
    
    // Find points that are significantly inside the fitted circle (flat edge)
    std::vector<cv::Point> flatEdgePoints;
    float threshold = circleRadius * 0.85;  // Points closer than 85% are flat edge
    
    for (const auto& pt : ledContour) {
        float dist = cv::norm(pt - cv::Point(circleCenter));
        if (dist < threshold) {
            flatEdgePoints.push_back(pt);
        }
    }
    
    // If we found a flat edge, calculate its orientation
    if (flatEdgePoints.size() >= 5) {
        // Fit a line to the flat edge points
        cv::Vec4f line;
        cv::fitLine(flatEdgePoints, line, cv::DIST_L2, 0, 0.01, 0.01);
        
        // Calculate angle of the flat edge
        float vx = line[0];
        float vy = line[1];
        float angle = atan2(vy, vx) * 180.0 / M_PI;
        
        // The cathode direction is perpendicular to the flat edge
        float cathodeAngle = angle + 90;
        
        // Normalize angle to 0-360
        while (cathodeAngle < 0) cathodeAngle += 360;
        while (cathodeAngle >= 360) cathodeAngle -= 360;
        
        // Determine cardinal direction
        const char* direction;
        if (cathodeAngle >= 337.5 || cathodeAngle < 22.5) direction = "RIGHT";
        else if (cathodeAngle >= 22.5 && cathodeAngle < 67.5) direction = "DOWN-RIGHT";
        else if (cathodeAngle >= 67.5 && cathodeAngle < 112.5) direction = "DOWN";
        else if (cathodeAngle >= 112.5 && cathodeAngle < 157.5) direction = "DOWN-LEFT";
        else if (cathodeAngle >= 157.5 && cathodeAngle < 202.5) direction = "LEFT";
        else if (cathodeAngle >= 202.5 && cathodeAngle < 247.5) direction = "UP-LEFT";
        else if (cathodeAngle >= 247.5 && cathodeAngle < 292.5) direction = "UP";
        else direction = "UP-RIGHT";
        
        // Draw prominent arrow pointing to cathode
        float arrowLength = radius * 1.8;
        cv::Point arrowEnd(
            center.x + arrowLength * cos(cathodeAngle * M_PI / 180.0),
            center.y + arrowLength * sin(cathodeAngle * M_PI / 180.0)
        );
        
        // Draw thick arrow with glow effect
        cv::arrowedLine(result, center, arrowEnd, cv::Scalar(50, 50, 150), 5, cv::LINE_AA, 0, 0.35);
        cv::arrowedLine(result, center, arrowEnd, cv::Scalar(0, 0, 255), 3, cv::LINE_AA, 0, 0.35);
        
        // Draw the flat edge prominently
        for (const auto& pt : flatEdgePoints) {
            cv::circle(result, pt, 3, cv::Scalar(255, 0, 255), -1);
        }
        
        // Add prominent label box
        int labelY = center.y - radius - 50;
        int labelX = center.x - 120;
        
        // Background box for label
        cv::rectangle(result, cv::Point(labelX - 5, labelY - 25), 
                      cv::Point(labelX + 240, labelY + 40),
                      cv::Scalar(0, 0, 0), -1);
        cv::rectangle(result, cv::Point(labelX - 5, labelY - 25), 
                      cv::Point(labelX + 240, labelY + 40),
                      cv::Scalar(0, 0, 255), 2);
        
        // Main direction label
        char mainLabel[100];
        sprintf(mainLabel, "CATHODE -> %s", direction);
        cv::putText(result, mainLabel, cv::Point(labelX, labelY),
                    cv::FONT_HERSHEY_DUPLEX, 0.6, cv::Scalar(0, 100, 255), 2);
        cv::putText(result, mainLabel, cv::Point(labelX, labelY),
                    cv::FONT_HERSHEY_DUPLEX, 0.6, cv::Scalar(100, 200, 255), 1);
        
        // Angle and confidence
        float confidence = (float)flatEdgePoints.size() / ledContour.size();
        char detailLabel[100];
        sprintf(detailLabel, "Angle: %.0f deg | Conf: %.0f%%", cathodeAngle, confidence * 100);
        cv::putText(result, detailLabel, cv::Point(labelX, labelY + 25),
                    cv::FONT_HERSHEY_SIMPLEX, 0.45, cv::Scalar(200, 200, 200), 1);
    }
}

- (cv::Mat)cvMatFromCGImage:(CGImageRef)image {
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image);
    CGFloat cols = CGImageGetWidth(image);
    CGFloat rows = CGImageGetHeight(image);
    
    cv::Mat cvMat(rows, cols, CV_8UC4);
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,
                                                     cols,
                                                     rows,
                                                     8,
                                                     cvMat.step[0],
                                                     colorSpace,
                                                     kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault);
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image);
    CGContextRelease(contextRef);
    
    cv::Mat result;
    cv::cvtColor(cvMat, result, cv::COLOR_RGBA2BGR);
    
    return result;
}

- (NSImage *)NSImageFromCVMat:(cv::Mat)cvMat {
    cv::Mat rgbaMat;
    if (cvMat.channels() == 3) {
        cv::cvtColor(cvMat, rgbaMat, cv::COLOR_BGR2RGBA);
    } else if (cvMat.channels() == 4) {
        cv::cvtColor(cvMat, rgbaMat, cv::COLOR_BGRA2RGBA);
    } else if (cvMat.channels() == 1) {
        cv::cvtColor(cvMat, rgbaMat, cv::COLOR_GRAY2RGBA);
    } else {
        rgbaMat = cvMat.clone();
    }
    
    size_t dataLength = rgbaMat.total() * rgbaMat.elemSize();
    NSMutableData *data = [NSMutableData dataWithBytes:rgbaMat.data length:dataLength];
    unsigned char *dataPtr = (unsigned char *)data.mutableBytes;
    
    NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc]
                                   initWithBitmapDataPlanes:&dataPtr
                                   pixelsWide:rgbaMat.cols
                                   pixelsHigh:rgbaMat.rows
                                   bitsPerSample:8
                                   samplesPerPixel:4
                                   hasAlpha:YES
                                   isPlanar:NO
                                   colorSpaceName:NSDeviceRGBColorSpace
                                   bitmapFormat:0
                                   bytesPerRow:rgbaMat.step[0]
                                   bitsPerPixel:32];
    
    NSImage *finalImage = [[NSImage alloc] initWithSize:NSMakeSize(rgbaMat.cols, rgbaMat.rows)];
    [finalImage addRepresentation:imageRep];
    
    return finalImage;
}

@end
