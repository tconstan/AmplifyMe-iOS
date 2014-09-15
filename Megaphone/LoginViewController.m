#import "LoginViewController.h"
#import "Logger.h"
#import "BeaconService.h"
#import "MButton.h"

@interface LoginViewController ()

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *loadingIndicator;
@property (weak, nonatomic) IBOutlet MButton *buttonLogin;

@end

@implementation LoginViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    UIImage *background = [UIImage imageNamed: @"loginBackground.png"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:background];
    
    [self.view insertSubview:imageView atIndex:0];
    [self.buttonLogin showShadowAtBottom];
}

- (IBAction)loginTapped:(id)sender {
    NSLog(@"Bundle ID: %@",[[NSBundle mainBundle] bundleIdentifier]);
    [sender setHidden:YES];
    [self.loadingIndicator startAnimating];
    
    NSArray *permissionsArray = @[@"user_about_me", @"user_location", @"user_friends"];
    [PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
        [self.loadingIndicator stopAnimating];
        
        NSLog(@"Username: %@", user.username);
        NSLog(@"Password: %@", user.password);
        if (!user) {
            if (!error) {
                NSLog(@"Uh oh. The user cancelled the Facebook login.");
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Uh oh, something went wrong"
                                                                message:@"If you have the Facebook App installed, make sure you're credentials in iPhone settings are correct and you've authorized AmplifyMe."
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"Dismiss", nil)
                                                      otherButtonTitles:nil];
                [alert show];
            }
            
            [sender setHidden:NO];
        } else if (user.isNew) {
            [self performSegueWithIdentifier:@"UnwindFromLogin" sender:self];
        } else {
            [self performSegueWithIdentifier:@"UnwindFromLogin" sender:self];
        }
    }];
}

@end
