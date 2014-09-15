//
//  BroadcastHeaderInfoTableViewCell.h
//  AmplifyMe
//
//  Created by Thomas Constantin on 2014-08-24.
//
//

#import <UIKit/UIKit.h>

@protocol BroadcastHeaderInfoTableViewCellDelegate <NSObject>

- (void)updateBroadcastInfoWithText:(NSString *)string forState:(NSString *)state;
- (void)updateTitleFilledState:(BOOL)isFilled;

@end

@interface BroadcastHeaderInfoTableViewCell : UITableViewCell <UITextFieldDelegate, UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UITextField *textFieldLabel;
@property (weak, nonatomic) IBOutlet UITextView *textViewMessage;
@property (weak, nonatomic) IBOutlet UILabel *labelPlaceholderMessage;

@property (nonatomic, weak) id <BroadcastHeaderInfoTableViewCellDelegate> delegate;

@end
