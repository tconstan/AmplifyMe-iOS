#import "BroadcastAnnotation.h"
#import <ParseFacebookUtils/PFFacebookUtils.h>
#import <Parse/Parse.h>

@implementation BroadcastAnnotation

- (instancetype)initWithBroadcast:(PFObject *)broadcast {
    if (self = [super init]) {
        PFGeoPoint *geoPoint = broadcast[@"location"];
        self.coordinate = CLLocationCoordinate2DMake(geoPoint.latitude, geoPoint.longitude);
    }
    return self;
}

@end
