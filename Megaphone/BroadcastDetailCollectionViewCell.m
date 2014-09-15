//
//  BroadcastDetailCollectionViewCell.m
//  AmplifyMe
//
//  Created by Thomas Constantin on 2014-08-16.
//
//

#import "BroadcastDetailCollectionViewCell.h"
#import "BaseUtils.h"

@interface BroadcastDetailCollectionViewCell ()
@property (strong, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation BroadcastDetailCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.imageView = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
        [self.contentView addSubview:self.imageView];
    }
    return self;
}

- (void)populateCellWithImage:(UIImage *)image atIndex:(NSInteger)index andBorder:(BOOL)border{
    self.imageView.image = [BaseUtils createIcon:image iconSize:172];
    self.imageView.layer.cornerRadius = 5.0f;
    self.imageView.layer.masksToBounds = YES;
    if (border) {
        [self.imageView.layer setBorderColor:[[UIColor redColor] CGColor]];
        [self.imageView.layer setBorderWidth: 2.0];
    } else {
        [self.imageView.layer setBorderColor:[[UIColor clearColor] CGColor]];
        [self.imageView.layer setBorderWidth: 0.0];
    }
    [self.contentView addSubview:self.imageView];
}

@end
