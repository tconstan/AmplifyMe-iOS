@class BeaconService;

@protocol BeaconServiceObserver <NSObject>

- (void)service:(BeaconService *)service updatedLocation:(CLLocation *)location;

@end

@protocol BeaconServiceDelegate <NSObject>

- (void)updateLocation;

@end

@interface BeaconService : NSObject

@property (nonatomic, strong) PFObject *broadcast;
@property (nonatomic, strong, readonly) CLLocation *mostRecentLocation;

@property (nonatomic, assign, readonly, getter = isUpdating) BOOL updating;
@property (nonatomic, weak) id <BeaconServiceDelegate> delegate;


+ (instancetype)sharedService;

- (void)addObserver:(id<BeaconServiceObserver>)observer;
- (void)removeObserver:(id<BeaconServiceObserver>)observer;

- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;

@end
