//
//  DatePickerTableViewCell.h
//  AmplifyMe
//
//  Created by Thomas Constantin on 2014-08-24.
//
//

#import <UIKit/UIKit.h>

@class DatePickerTableViewCell;

@protocol DatePickerTableViewCellDelegate <NSObject>

- (void)notifyDateTimeChanged:(NSDate *)date withState:(NSString *)state;

@end

@interface DatePickerTableViewCell : UITableViewCell
@property (nonatomic, strong) IBOutlet UIDatePicker *pickerView;
@property (nonatomic, strong) NSString *statePressed;
@property (nonatomic, weak) id <DatePickerTableViewCellDelegate> delegate;

- (void)showPickerView:(BOOL)showPickerView withDate:(NSDate *)date;

@end
