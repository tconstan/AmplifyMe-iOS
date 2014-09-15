//
//  MButton.m
//  AmplifyMe
//
//  Created by Thomas Constantin on 2014-08-20.
//
//

#import "MButton.h"

@interface MButton ()

@property (nonatomic, strong) CALayer *shadowLayer;

@end

@implementation MButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)awakeFromNib {
    [super awakeFromNib];
    self.shadowLayer = [[CALayer alloc] init];
    self.shadowLayer.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3].CGColor;
    self.shadowLayer.frame = CGRectMake(0, CGRectGetHeight(self.frame) - 2, CGRectGetWidth(self.frame), 2);
    [self.layer addSublayer:self.shadowLayer];
    self.shadowLayer.hidden = YES;
}

- (void)showShadowAtBottom
{
    self.shadowLayer.frame = CGRectMake(0, CGRectGetHeight(self.frame) - 2, CGRectGetWidth(self.frame), 2);
    self.shadowLayer.hidden = NO;
}

@end
