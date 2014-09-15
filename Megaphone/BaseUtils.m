//
//  BaseUtils.m
//  AmplifyMe
//
//  Created by Thomas Constantin on 2014-08-11.
//
//

#import "BaseUtils.h"
#import "UIColor+Megaphone.h"
#import "TTTAttributedLabel.h"
#import "FBUsers.h"

@implementation BaseUtils

+ (NSString*)formatAttendingStringWithArray:(NSMutableArray *)inputArray {
    NSString *formattedString = @"";
    NSInteger size = [inputArray count];
    
    if (size == 1) {
        formattedString = [formattedString stringByAppendingString:[NSString stringWithFormat:@"%@ is going", [inputArray objectAtIndex:0]]];
    } else if (size == 2) {
        formattedString = [formattedString stringByAppendingString:[NSString stringWithFormat:@"%@ and %@ are going", [inputArray objectAtIndex:0], [inputArray objectAtIndex:1]]];
    } else if (size > 2){
        formattedString = [formattedString stringByAppendingString:[NSString stringWithFormat:@"%@, %@ and %ld others are going", [inputArray objectAtIndex:0], [inputArray objectAtIndex:1], size - 2]];
        
    }
    
    return formattedString;
}

+ (NSString*)formatAttendingStringWithArrayForCondensedString:(NSMutableArray *)inputArray {
    NSString *formattedString = @"";
    NSInteger size = [inputArray count];
    
    if (size == 1) {
        formattedString = [formattedString stringByAppendingString:[NSString stringWithFormat:@"%@ is going", [inputArray objectAtIndex:0]]];
    } else if (size > 1){
        formattedString = [formattedString stringByAppendingString:[NSString stringWithFormat:@"%@ and %ld others are going", [inputArray objectAtIndex:0], size - 1]];
        
    }
    
    return formattedString;
}

+ (void)styleNavigationBar:(UINavigationBar *)navBar {
    navBar.barTintColor = [UIColor defaultOrangeColor];
    navBar.translucent = NO;
    
    [navBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    [navBar setBarStyle:UIBarStyleBlack];
    [navBar setTintColor:[UIColor whiteColor]];
}

+ (NSString *)loadDateFormatterForDate:(NSDate *)date addPrefix:(BOOL)addPrefix{
    NSString *returnDate = @"";
    
    NSDate *currentDate = [NSDate date];
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *componentsCurrentDate = [gregorian components:(NSDayCalendarUnit | NSWeekdayCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit) fromDate:currentDate];
    NSInteger yearCurrentDate = [componentsCurrentDate year];
    NSInteger monthCurrentDate = [componentsCurrentDate month];
    NSInteger dayCurrentDate = [componentsCurrentDate day];
    
    NSDateComponents *components = [gregorian components:(NSDayCalendarUnit | NSWeekdayCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit) fromDate:date];
    NSInteger yearDate = [components year];
    NSInteger monthDate = [components month];
    NSInteger dayDate = [components day];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMM. dd yyyy, HH:mm a"];
    returnDate = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:date]];
    
    if ([self matchingYear:yearCurrentDate with:yearDate]) {
        [dateFormatter setDateFormat:@"MMM. dd, HH:mm a"];
        returnDate = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:date]];
        if ([self matchingMonth:monthCurrentDate with:monthDate]) {
            if ([self matchingWeek:dayCurrentDate with:dayDate]) {
                [dateFormatter setDateFormat:@"EEE. HH:mm a"];
                returnDate = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:date]];
                if ([self matchingDay:dayCurrentDate with:dayDate]) {
                    [dateFormatter setDateFormat:@"HH:mm a"];
                    if (addPrefix) {
                        returnDate = [NSString stringWithFormat:@"Today at %@", [dateFormatter stringFromDate:date]];
                    } else {
                        returnDate = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:date]];
                    }
                }
                else if ([self isTomorrow:dayCurrentDate with:dayDate]) {
                    [dateFormatter setDateFormat:@"HH:mm a"];
                    if (addPrefix) {
                        returnDate = [NSString stringWithFormat:@"Tomorrow at %@", [dateFormatter stringFromDate:date]];
                    } else {
                        returnDate = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:date]];
                    }
                }
            }
        }
    }
    return returnDate;
}

+ (BOOL)matchingYear:(NSInteger)year1 with:(NSInteger)year2 {
    if (year1 == year2) {
        return YES;
    }
    return NO;
}

+ (BOOL)matchingMonth:(NSInteger)month1 with:(NSInteger)month2 {
    if (month1 == month2) {
        return YES;
    }
    return NO;
}

+ (BOOL)matchingWeek:(NSInteger)day1 with:(NSInteger)day2 {
    if (day1 + 7 - day2 <= 7) {
        return YES;
    }
    return NO;
}

+ (BOOL)isTomorrow:(NSInteger)day1 with:(NSInteger)day2 {
    if (day1 + 1 - day2 == 0) {
        return YES;
    }
    return NO;
}

+ (BOOL)matchingDay:(NSInteger)day1 with:(NSInteger)day2 {
    if (day1 == day2) {
        return YES;
    }
    return NO;
}

// A function for parsing URL parameters returned by the Feed Dialog.
+ (NSDictionary*)parseURLParams:(NSString *)query {
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val =
        [kv[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        params[kv[0]] = val;
    }
    return params;
}

+ (UIImage *)croppIngimageByImageName:(UIImage *)imageToCrop toRect:(CGRect)rect
{
    //CGRect CropRect = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height+15);
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([imageToCrop CGImage], rect);
    UIImage *cropped = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return cropped;
}

+ (UIImage *)createIcon: (UIImage *)image iconSize:(int)size{
    UIImage *newImage = nil;
    if (image.size.height > image.size.width) {
        CGRect cropRect = CGRectMake(0,(abs(image.size.width - image.size.height))/2, image.size.width, image.size.width); //set your rect size.
        newImage = [self croppIngimageByImageName:image toRect:cropRect];
    }else{
        CGRect cropRect = CGRectMake((abs(image.size.width - image.size.height))/2,0, image.size.height, image.size.height); //set your rect size.
        newImage = [self croppIngimageByImageName:image toRect:cropRect];
    }
    CGSize itemSize = CGSizeMake(size,size);
    UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
    CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
    [newImage drawInRect:imageRect];
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

+ (UIImage *)fixOrientationForImage:(UIImage *)image {
    
    // No-op if the orientation is already correct
    if (image.imageOrientation == UIImageOrientationUp) return image;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (image.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, image.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    
    switch (image.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, image.size.width, image.size.height,
                                             CGImageGetBitsPerComponent(image.CGImage), 0,
                                             CGImageGetColorSpace(image.CGImage),
                                             CGImageGetBitmapInfo(image.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.height,image.size.width), image.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.width,image.size.height), image.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}
@end
