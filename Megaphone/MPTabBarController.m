#import "MPTabBarController.h"
#import "BeaconService.h"
#import "LoginViewController.h"
#import <ParseFacebookUtils/PFFacebookUtils.h>

@interface MPTabBarController ()

@end

@implementation MPTabBarController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!([self isAuthenticated])) {
        [self performSegueWithIdentifier:@"ShowLogin" sender:self];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}

- (void)logOut {
    [[BeaconService sharedService] stopUpdatingLocation];
    [PFUser logOut];
    [self performSegueWithIdentifier:@"ShowLogin" sender:self];
}

- (BOOL)isAuthenticated {
    return [PFUser currentUser] && [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]];
}

- (IBAction)unwindFromLogin:(UIStoryboardSegue *)segue {
    [[BeaconService sharedService] startUpdatingLocation];
    [self setSelectedIndex:0];
}

//- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    if ([segue.identifier isEqualToString:@"ShowLogin"]) {
//        LoginViewController *detailVC = segue.destinationViewController;
//    }
//}

@end
