@interface BroadcastAnnotation : NSObject <MKAnnotation>

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

- (instancetype)initWithBroadcast:(PFObject *)broadcast;

@end
