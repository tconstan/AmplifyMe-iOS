//
//  NotificationTableViewCell.m
//  AmplifyMe
//
//  Created by Thomas Constantin on 2014-08-17.
//
//

#import "NotificationTableViewCell.h"
#import "TTTAttributedLabel.h"

@interface NotificationTableViewCell () <TTTAttributedLabelDelegate>

@property (weak, nonatomic) IBOutlet TTTAttributedLabel *labelNotificationTitle;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewNotificationType;

@property (nonatomic, strong) NSString *eventInvitee;
@property (nonatomic, strong) NSString *eventTitle;
@property (nonatomic, strong) NSDate *eventDateCreated;

@property (nonatomic, strong) NSDictionary *notificationInfo;

@end

@implementation NotificationTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)populateCellWithInfo:(NSDictionary *)dict {
    self.notificationInfo = [[NSDictionary alloc] initWithDictionary:dict];
    self.labelNotificationTitle.text = [self.notificationInfo objectForKey:@"message"];
    self.eventInvitee = [self.notificationInfo objectForKey:@"eventInvitee"];
    self.eventTitle = [self.notificationInfo objectForKey:@"title"];
    self.eventDateCreated = [self.notificationInfo objectForKey:@"dateCreated"];
    
    NSRange textRange = [self.labelNotificationTitle.text rangeOfString:self.eventTitle];
    if (textRange.location != NSNotFound) {
        //textrange found
        NSString *param = [self.labelNotificationTitle.text substringFromIndex:textRange.location + textRange.length];
        self.labelNotificationTitle.delegate = self;
        self.labelNotificationTitle.linkAttributes = @{ NSFontAttributeName : [UIFont boldSystemFontOfSize:self.labelNotificationTitle.font.pointSize],
                                                        NSForegroundColorAttributeName: [UIColor blackColor],
                                                        NSUnderlineStyleAttributeName: [NSNumber numberWithInt:0] };
        [self.labelNotificationTitle addLinkToAddress: @{
                                                 param : param
                                                 }
                                    withRange: textRange];
        
    }

    PFFile *imageFile = [self.notificationInfo objectForKey:@"photoFile"];
    [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        self.imageViewNotificationType.image = [UIImage imageWithData:data scale:1.0f];
        self.imageViewNotificationType.layer.cornerRadius = 5.0f;
        self.imageViewNotificationType.layer.masksToBounds = YES;
    }];
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithAddress:(NSDictionary *)addressComponents {
    [self.delegate performSegueForNotification:self withTitle:[self.notificationInfo objectForKey:@"title"]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
@end
