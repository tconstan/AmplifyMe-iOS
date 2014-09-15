#import "ParseStarterProjectAppDelegate.h"
#import "ParseStarterProjectViewController.h"

#import "BeaconService.h"
#import "Constants.h"

@interface ParseStarterProjectAppDelegate ()

@property (nonatomic, strong) UIApplication *app;
@property (nonatomic) BOOL locationStarted;

@end

@implementation ParseStarterProjectAppDelegate

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [self styleAppearance];
    self.app = [UIApplication sharedApplication];
    self.locationStarted = NO;
    [FBLoginView class];
    
    [Parse setApplicationId:kParseApplicationId
                  clientKey:kParseClientKey];
    
    [PFFacebookUtils initializeFacebook];
    
    if (application.applicationState != UIApplicationStateBackground) {
        // Track an app open here if we launch with a push, unless
        // "content_available" was used to trigger a background push (introduced
        // in iOS 7). In that case, we skip tracking here to avoid double
        // counting the app-open.
        BOOL preBackgroundPush = ![application respondsToSelector:@selector(backgroundRefreshStatus)];
        BOOL oldPushHandlerOnly = ![self respondsToSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)];
        BOOL noPushPayload = ![launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (preBackgroundPush || oldPushHandlerOnly || noPushPayload) {
            [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
        }
    }
    
    [application registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                     UIRemoteNotificationTypeAlert |
                                                     UIRemoteNotificationTypeSound)];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
    sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [FBAppCall handleOpenURL:url
           sourceApplication:sourceApplication
                 withSession:[PFFacebookUtils session]];
//    return [PFFacebookUtils handleOpenURL:url];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {
    [PFPush storeDeviceToken:newDeviceToken];
    [PFPush subscribeToChannelInBackground:@"" target:self selector:@selector(subscribeFinished:error:)];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if (error.code == 3010) {
        NSLog(@"Push notifications are not supported in the iOS Simulator.");
    } else {
        // show some alert or otherwise handle the failure to register.
        NSLog(@"application:didFailToRegisterForRemoteNotificationsWithError: %@", error);
	}
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [PFPush handlePush:userInfo];

    if (application.applicationState == UIApplicationStateInactive) {
        [PFAnalytics trackAppOpenedWithRemoteNotificationPayload:userInfo];
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    if (application.applicationState == UIApplicationStateInactive) {
        [PFAnalytics trackAppOpenedWithRemoteNotificationPayload:userInfo];
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

//run background task
- (void)runBackgroundTask: (int) time{
    //check if application is in background mode
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        
        //create UIBackgroundTaskIdentifier and create background task, which starts after time
        __block UIBackgroundTaskIdentifier bgTask = [self.app beginBackgroundTaskWithExpirationHandler:^{
            [self.app endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
        }];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSTimer* t = [NSTimer scheduledTimerWithTimeInterval:time target:self selector:@selector(startTrackingBg) userInfo:nil repeats:NO];
            [[NSRunLoop currentRunLoop] addTimer:t forMode:NSDefaultRunLoopMode];
            [[NSRunLoop currentRunLoop] run];
        });
    }
}

- (void)startTrackingBg{
    //write background time remaining
    NSLog(@"backgroundTimeRemaining: %.0f", [[UIApplication sharedApplication] backgroundTimeRemaining]);
    
    //set default time
    int time = 60;
    //if locationManager is ON
    if (self.locationStarted == YES ) {
        //stop update location
        [[BeaconService sharedService] stopUpdatingLocation];
        self.locationStarted = NO;
    }else{
        //start updating location
        [[BeaconService sharedService] startUpdatingLocation];
        self.locationStarted = YES;
        //ime how long the application will update your location
        time = 5;
    }
    
    [self runBackgroundTask:time];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
//    //check if application status is in background
//    if ( [UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
//        //start updating location with location manager
//        [[BeaconService sharedService] startUpdatingLocation];
//    }
    
    [[BeaconService sharedService] stopUpdatingLocation];
    
    //change locationManager status after time
//    [self runBackgroundTask:20];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    self.locationStarted = NO;
    [[BeaconService sharedService] startUpdatingLocation];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FBAppCall handleDidBecomeActiveWithSession:[PFFacebookUtils session]];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[PFFacebookUtils session] close];
}

- (void)subscribeFinished:(NSNumber *)result error:(NSError *)error {
    if ([result boolValue]) {
        NSLog(@"ParseStarterProject successfully subscribed to push notifications on the broadcast channel.");
    } else {
        NSLog(@"ParseStarterProject failed to subscribe to push notifications on the broadcast channel.");
    }
}

- (void)styleAppearance {
    UITabBar *tabBar = [UITabBar appearance];
    UIColor *redColor = [UIColor colorWithRed:255.0f/255.0f green:31.0f/255.0f blue:31.0f/255.0f alpha:1.0f];
    tabBar.tintColor = redColor;
    
    UINavigationBar *navigationBar = [UINavigationBar appearance];
    [navigationBar setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontWithName:@"AvenirNext-DemiBold"
                                                                                  size:17.0f]}];
    
    UITabBarItem *tabBarItem = [UITabBarItem appearance];
    [tabBarItem setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontWithName:@"AvenirNext-Medium"
                                                                               size:10.0f],
                                         NSForegroundColorAttributeName : [UIColor darkGrayColor]}
                              forState:UIControlStateNormal];
    
    [tabBarItem setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontWithName:@"AvenirNext-Medium"
                                                                               size:10.0f],
                                         NSForegroundColorAttributeName : redColor}
                              forState:UIControlStateSelected];
}

@end
