//
//  ViewController.m
//  WLUnitField
//
//  Created by wayne on 16/11/22.
//  Copyright © 2016年 wayne. All rights reserved.
//

#import "ViewController.h"
#import "WLUnitField.h"
#import "UIColor+randomColor.h"

@interface ViewController () <WLUnitFieldDelegate>

@property (strong, nonatomic) IBOutlet WLUnitField *unitField;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _unitField.delegate = self;
    _unitField.keyboardType = UIKeyboardTypeASCIICapable;
    _unitField.text = @"一😀12";
}

- (BOOL)unitField:(WLUnitField *)uniField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *text = nil;
    if (range.location >= uniField.text.length) {
        text = [uniField.text stringByAppendingString:string];
    } else {
        text = [uniField.text stringByReplacingCharactersInRange:range withString:string];
    }
    NSLog(@"******>%@", text);
    
    return YES;
}

- (IBAction)unitFieldEditingChanged:(WLUnitField *)sender {
     NSLog(@"%s, %@", __FUNCTION__, sender.text);
}

- (IBAction)unitFieldEditingDidBegin:(id)sender {
    NSLog(@"%s", __FUNCTION__);
}

- (IBAction)unitFieldEditingDidEnd:(id)sender {
     NSLog(@"%s", __FUNCTION__);
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view.window endEditing:YES];
}

- (IBAction)switchValueChanged:(UISwitch *)sender {
    if (sender.tag == 1) {
        _unitField.secureTextEntry = sender.isOn;
    } else if (sender.tag == 2) {
        _unitField.autoResignFirstResponderWhenInputFinished = sender.isOn;
    }
}

- (IBAction)stepperValueChanged:(UIStepper *)sender {
    if (sender.tag == 4) {
        UILabel *lab = [self.view viewWithTag:3];
        lab.text = [NSString stringWithFormat:@"%@", @(sender.value)];
        _unitField.unitSpace = sender.value;
    } else if (sender.tag == 6) {
        UILabel *lab = [self.view viewWithTag:5];
        lab.text = [NSString stringWithFormat:@"%@", @(sender.value)];
        _unitField.borderRadius = sender.value;
    } else if (sender.tag == 8) {
        UILabel *lab = [self.view viewWithTag:7];
        lab.text = [NSString stringWithFormat:@"%@", @(sender.value)];
        _unitField.borderWidth = sender.value;
    }
    
}

- (IBAction)buttonTouchUpInside:(UIButton *)sender {
    UIColor *color = [UIColor randomColor];
    [sender setBackgroundColor:color];
    
    if (sender.tag == 9) {
        _unitField.textColor = color;
    } else if (sender.tag == 10) {
        _unitField.tintColor = color;
    } else if (sender.tag == 11) {
        _unitField.trackTintColor = color;
    } else if (sender.tag == 12) {
        _unitField.cursorColor = color;
    }
}

@end
