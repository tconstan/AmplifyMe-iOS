#import "BeaconService.h"
#import "Logger.h"
#import "Constants.h"

@interface BeaconService () <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSMutableSet *observers;
@property (nonatomic, assign, getter = isUpdating) BOOL updating;

@property (nonatomic, strong) CLLocation *mostRecentLocation;

@end

@implementation BeaconService

+ (instancetype)sharedService {
    static dispatch_once_t once;
    static BeaconService *service;
    
    dispatch_once(&once, ^{
        service = [[self alloc] init];
    });
    
    return service;
}

- (instancetype)init {
    if (self = [super init]) {
        self.observers = [NSMutableSet set];
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
    }
    return self;
}

- (void)addObserver:(id<BeaconServiceObserver>)observer {
    [self.observers addObject:observer];
}

- (void)removeObserver:(id<BeaconServiceObserver>)observer {
    [self.observers removeObject:observer];
}

- (CLBeaconRegion *)megaphoneRegion {
    NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:kMegaphoneUUID];
    return [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID
                                              identifier:kAppIdentifier];
}

- (void)startUpdatingLocation {
    self.updating = YES;
    [self.locationManager startUpdatingLocation];
}

- (void)stopUpdatingLocation {
    self.updating = NO;
    [self.locationManager stopUpdatingLocation];
}

#pragma mark - <CLLocationManagerDelegate>

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *mostRecentLocation = locations.lastObject;
    
    if (self.broadcast != nil) {
        PFGeoPoint *location = [PFGeoPoint geoPointWithLatitude:mostRecentLocation.coordinate.latitude
                                                      longitude:mostRecentLocation.coordinate.longitude];
        
        self.broadcast[@"location"] = location;
        [self.broadcast saveEventually];
    }
    
    if (mostRecentLocation != nil) {
        self.mostRecentLocation = mostRecentLocation;
        
        for (id<BeaconServiceObserver> observer in self.observers) {
            if ([observer respondsToSelector:@selector(service:updatedLocation:)]) {
                [observer service:self updatedLocation:mostRecentLocation];
                [self.delegate updateLocation];
            }
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [Logger handleError:error];
}

@end
