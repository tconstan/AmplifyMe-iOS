//
//  BroadcastHeaderInfoTableViewCell.m
//  AmplifyMe
//
//  Created by Thomas Constantin on 2014-08-24.
//
//

#import "BroadcastHeaderInfoTableViewCell.h"

@interface BroadcastHeaderInfoTableViewCell ()

@end

@implementation BroadcastHeaderInfoTableViewCell

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

-(void)layoutSubviews
{
    self.textViewMessage.delegate = self;
    self.textFieldLabel.delegate = self;
    
    self.textFieldLabel.layer.sublayerTransform = CATransform3DMakeTranslation(5, 0, 0);
    
    if ([self.textFieldLabel.text isEqual: @""]) {
        self.textFieldLabel.layer.masksToBounds = YES;
        self.textFieldLabel.layer.borderColor = [[UIColor redColor] CGColor];
        self.textFieldLabel.layer.borderWidth = 2.0f;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

#pragma mark - IBAction

- (IBAction)textChanged:(id)sender {
    if ([self.textFieldLabel.text length] > 0) {
        [self.delegate updateTitleFilledState:YES];
        [self.delegate updateBroadcastInfoWithText:self.textFieldLabel.text forState:@"title"];
        self.textFieldLabel.layer.borderColor = [[UIColor clearColor] CGColor];
    } else {
        [self.delegate updateTitleFilledState:NO];
        self.textFieldLabel.layer.masksToBounds = YES;
        self.textFieldLabel.layer.borderColor = [[UIColor redColor] CGColor];
        self.textFieldLabel.layer.borderWidth = 2.0f;
    }
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    if ([self.textViewMessage.text length] > 0) {
        [self.textViewMessage setBackgroundColor:[UIColor whiteColor]];
        [self.labelPlaceholderMessage setHidden:YES];
        [self.delegate updateBroadcastInfoWithText:self.textViewMessage.text forState:@"message"];
    } else {
        [self.textViewMessage setBackgroundColor:[UIColor clearColor]];
        [self.labelPlaceholderMessage setHidden:NO];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    [self.delegate updateBroadcastInfoWithText:self.textViewMessage.text forState:@"message"];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [self.textViewMessage resignFirstResponder];
    }
    return YES;
}

#pragma mark - UITextFieldDelegate

-(BOOL)textFieldShouldReturn:(UITextField*)textField {
    [self.textViewMessage becomeFirstResponder];
    return NO;
}

@end
