//
//  DatePickerTableViewCell.m
//  AmplifyMe
//
//  Created by Thomas Constantin on 2014-08-24.
//
//

#import "DatePickerTableViewCell.h"

@interface DatePickerTableViewCell ()

@end

@implementation DatePickerTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    [self.pickerView addTarget:self
                        action:@selector(datePickerValueChanged:)
              forControlEvents:UIControlEventValueChanged];
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)showPickerView:(BOOL)showPickerView withDate:(NSDate *)date{
    if (showPickerView) {
        self.pickerView.hidden = NO;
        if (date) {
            [self.pickerView setDate:date animated:YES];
        }
    } else {
        self.pickerView.hidden = YES;
    }
}

- (IBAction)datePickerValueChanged:(UIDatePicker *)datePicker {
    [self.delegate notifyDateTimeChanged:datePicker.date withState:self.statePressed];
}
@end
