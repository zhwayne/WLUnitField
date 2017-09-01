//
//  WLUnitField.m
//  WLUnitField
//
//  Created by wayne on 16/11/22.
//  Copyright © 2016年 wayne. All rights reserved.
//

#import "WLUnitField.h"

#define DEFAULT_CONTENT_SIZE_WITH_UNIT_COUNT(c) CGSizeMake(44 * c, 44)

#ifdef NSFoundationVersionNumber_iOS_9_x_Max
    NSNotificationName const WLUnitFieldDidBecomeFirstResponderNotification = @"WLUnitFieldDidBecomeFirstResponderNotification";
    NSNotificationName const WLUnitFieldDidResignFirstResponderNotification = @"WLUnitFieldDidResignFirstResponderNotification";
#else
    NSString *const WLUnitFieldDidBecomeFirstResponderNotification = @"WLUnitFieldDidBecomeFirstResponderNotification";
    NSString *const WLUnitFieldDidResignFirstResponderNotification = @"WLUnitFieldDidResignFirstResponderNotification";
#endif

@interface WLUnitField () <UIKeyInput>

@property (nonatomic, strong) NSMutableArray *characterArray;
@property (nonatomic, strong) CALayer *cursorLayer;

@end

@implementation WLUnitField
{
    UIColor *_backgroundColor;
    CGContextRef _ctx;
}

@dynamic text;
@synthesize secureTextEntry = _secureTextEntry;
@synthesize enablesReturnKeyAutomatically = _enablesReturnKeyAutomatically;
@synthesize keyboardType = _keyboardType;
@synthesize returnKeyType = _returnKeyType;

#pragma mark - Life

- (instancetype)initWithInputUnitCount:(NSUInteger)count {
    if (self = [super initWithFrame:CGRectZero]) {
        NSCAssert(count > 0, @"WLUnitField must have one or more input units.");
        NSCAssert(count <= 8, @"WLUnitField can not have more than 8 input units.");
        
        _inputUnitCount = count;
        [self initialize];
    }
    
    return self;
}


- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _inputUnitCount = 4;
        [self initialize];
    }
    
    return self;
}


- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _inputUnitCount = 4;
        [self initialize];
    }
    
    return self;
}



- (void)initialize {
    [self setBackgroundColor:[UIColor clearColor]];
    self.opaque = NO;
    _characterArray = [NSMutableArray array];
    _secureTextEntry = NO;
    _unitSpace = 12;
    _borderRadius = 0;
    _borderWidth = 1;
    _textFont = [UIFont systemFontOfSize:22];
    _keyboardType = UIKeyboardTypeNumberPad;
    _returnKeyType = UIReturnKeyDone;
    _enablesReturnKeyAutomatically = YES;
    _autoResignFirstResponderWhenInputFinished = NO;
    _textColor = [UIColor darkGrayColor];
    _tintColor = [UIColor lightGrayColor];
    _trackTintColor = [UIColor orangeColor];
    _cursorColor = [UIColor orangeColor];
    _backgroundColor = _backgroundColor ?: [UIColor clearColor];
    self.cursorLayer.backgroundColor = _cursorColor.CGColor;

    [self.layer addSublayer:self.cursorLayer];
    [self setNeedsDisplay];
}


#pragma mark - Property

- (NSString *)text {
    if (_characterArray.count == 0) return nil;
    return [_characterArray componentsJoinedByString:@""];
}


- (void)setText:(NSString *)text {
    
    [_characterArray removeAllObjects];
    [text enumerateSubstringsInRange:NSMakeRange(0, text.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
        if (self.characterArray.count < self.inputUnitCount)
            [self.characterArray addObject:substring];
        else
            *stop = YES;
    }];
    
    [self setNeedsDisplay];
}


- (CALayer *)cursorLayer {
    if (!_cursorLayer) {
        _cursorLayer = [CALayer layer];
        _cursorLayer.hidden = YES;
        _cursorLayer.opacity = 1;
        
        CABasicAnimation *animate = [CABasicAnimation animationWithKeyPath:@"opacity"];
        animate.fromValue = @(0);
        animate.toValue = @(1.5);
        animate.duration = 0.5;
        animate.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        animate.autoreverses = YES;
        animate.removedOnCompletion = NO;
        animate.fillMode = kCAFillModeForwards;
        animate.repeatCount = HUGE_VALF;
        
        [_cursorLayer addAnimation:animate forKey:nil];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self layoutIfNeeded];
            
            _cursorLayer.position = CGPointMake(CGRectGetWidth(self.bounds) / _inputUnitCount / 2, CGRectGetHeight(self.bounds) / 2);
        }];
    }
    
    return _cursorLayer;
}


- (void)setSecureTextEntry:(BOOL)secureTextEntry {
    _secureTextEntry = secureTextEntry;
    [self setNeedsDisplay];
    [self _resetCursorStateIfNeeded];
}


#if TARGET_INTERFACE_BUILDER
- (void)setInputUnitCount:(NSUInteger)inputUnitCount {
    inputUnitCount = MAX(1, MIN(8, inputUnitCount));
    
    _inputUnitCount = inputUnitCount;
    [self setNeedsDisplay];
    [self _resetCursorStateIfNeeded];
}
#endif


- (void)setUnitSpace:(CGFloat)unitSpace {
    if (unitSpace < 0) return;
    if (unitSpace < 2) unitSpace = 0;
    
    _unitSpace = unitSpace;
    [self _resize];
    [self setNeedsDisplay];
    [self _resetCursorStateIfNeeded];
}


- (void)setTextFont:(UIFont *)textFont {
    if (textFont == nil) {
        _textFont = [UIFont systemFontOfSize:22];
    } else {
        _textFont = textFont;
    }
    
    [self setNeedsDisplay];
    [self _resetCursorStateIfNeeded];
}


- (void)setTextColor:(UIColor *)textColor {
    if (textColor == nil) {
        _textColor = [UIColor blackColor];
    } else {
        _textColor = textColor;
    }
    
    [self setNeedsDisplay];
    [self _resetCursorStateIfNeeded];
}


- (void)setBorderRadius:(CGFloat)borderRadius {
    if (borderRadius < 0) return;
    
    _borderRadius = borderRadius;
    [self setNeedsDisplay];
    [self _resetCursorStateIfNeeded];
}


- (void)setBorderWidth:(CGFloat)borderWidth {
    if (borderWidth < 0) return;
    
    _borderWidth = borderWidth;
    [self setNeedsDisplay];
    [self _resetCursorStateIfNeeded];
}


- (void)setBackgroundColor:(UIColor *)backgroundColor {
    if (backgroundColor == nil) {
        _backgroundColor = [UIColor blackColor];
    } else {
        _backgroundColor = backgroundColor;
    }
    
    [self setNeedsDisplay];
    [self _resetCursorStateIfNeeded];
}


- (void)setTintColor:(UIColor *)tintColor {
    if (tintColor == nil) {
        _tintColor = [[UIView appearance] tintColor];
    } else {
        _tintColor = tintColor;
    }
    
    [self setNeedsDisplay];
    [self _resetCursorStateIfNeeded];
}


//- (void)setTintBackgroundColor:(UIColor *)tintBackgroundColor {
//    _tintBackgroundColor = tintBackgroundColor;
//    
//    [self setNeedsDisplay];
//    [self _resetCursorStateIfNeeded];
//}


- (void)setTrackTintColor:(UIColor *)trackTintColor {
    _trackTintColor = trackTintColor;
    [self setNeedsDisplay];
    [self _resetCursorStateIfNeeded];
}


//- (void)setTrackTintBackgroundColor:(UIColor *)trackTintBackgroundColor {
//    _trackTintBackgroundColor = trackTintBackgroundColor;
//    [self setNeedsDisplay];
//    [self _resetCursorStateIfNeeded];
//}


- (void)setCursorColor:(UIColor *)cursorColor {
    _cursorColor = cursorColor;
    _cursorLayer.backgroundColor = _cursorColor.CGColor;
    [self _resetCursorStateIfNeeded];
}


#pragma mark- Event

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    [self becomeFirstResponder];
}


#pragma mark - Override

- (CGSize)intrinsicContentSize {
    CGSize size = self.bounds.size;
    size.width = MAX(size.width, DEFAULT_CONTENT_SIZE_WITH_UNIT_COUNT(_inputUnitCount).width);
    CGFloat unitWidth = (size.width + _unitSpace) / _inputUnitCount - _unitSpace;
    size.height = unitWidth;
    
    return size;
}


- (CGSize)sizeThatFits:(CGSize)size {
    return [self intrinsicContentSize];
}


- (BOOL)canBecomeFirstResponder {
    return YES;
}


- (BOOL)becomeFirstResponder {
    BOOL result = [super becomeFirstResponder];
    [self _resetCursorStateIfNeeded];
    
    if (result ==  YES) {
        [self sendActionsForControlEvents:UIControlEventEditingDidBegin];
        [[NSNotificationCenter defaultCenter] postNotificationName:WLUnitFieldDidBecomeFirstResponderNotification object:nil];
    }
    
    return result;
}


- (BOOL)canResignFirstResponder {
    return YES;
}


- (BOOL)resignFirstResponder {
    BOOL result = [super resignFirstResponder];
    [self _resetCursorStateIfNeeded];
    
    if (result) {
        [self sendActionsForControlEvents:UIControlEventEditingDidEnd];
        [[NSNotificationCenter defaultCenter] postNotificationName:WLUnitFieldDidResignFirstResponderNotification object:nil];
    }
    
    return result;
}


- (void)drawRect:(CGRect)rect {
    /*
     *  绘制的线条具有宽度，因此在绘制时需要考虑该因素对绘制效果的影响。
     */
    CGSize unitSize = CGSizeMake((rect.size.width + _unitSpace) / _inputUnitCount - _unitSpace, rect.size.height);
    
    _ctx = UIGraphicsGetCurrentContext();

    [self _fillRect:rect clip:YES];
    [self _drawBorder:rect unitSize:unitSize];
    [self _drawText:rect unitSize:unitSize];
    [self _drawTrackBorder:rect unitSize:unitSize];
}

#pragma mark- Private

/**
 在 AutoLayout 环境下重新指定控件本身的固有尺寸
 
 `-drawRect:`方法会计算控件完成自身的绘制所需的合适尺寸，完成一次绘制后会通知 AutoLayout 系统更新尺寸。
 */
- (void)_resize {
    [self invalidateIntrinsicContentSize];
}


/**
 绘制背景色，以及剪裁绘制区域

 @param rect 控件绘制的区域
 @param clip 剪裁区域同时被`borderRadius`影响
 */
- (void)_fillRect:(CGRect)rect clip:(BOOL)clip {
    [_backgroundColor setFill];
    if (clip) {
        CGContextAddPath(_ctx, [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:_borderRadius].CGPath);
        CGContextClip(_ctx);
    }
    CGContextAddPath(_ctx, [UIBezierPath bezierPathWithRoundedRect:CGRectInset(rect, _borderWidth * 0.75, _borderWidth * 0.75) cornerRadius:_borderRadius].CGPath);
    CGContextFillPath(_ctx);
}


/**
 绘制边框
 
 边框的绘制分为两种模式：连续和不连续。其模式的切换由`unitSpace`属性决定。
 当`unitSpace`值小于 2 时，采用的是连续模式，即每个 input unit 之间没有间隔。
 反之，每个 input unit 会被边框包围。
 
 @see unitSpace
 
 @param rect 控件绘制的区域
 @param unitSize 单个 input unit 占据的尺寸
 */
- (void)_drawBorder:(CGRect)rect unitSize:(CGSize)unitSize {
    
    [self.tintColor setStroke];
    CGContextSetLineWidth(_ctx, _borderWidth);
    CGContextSetLineCap(_ctx, kCGLineCapRound);
    CGRect bounds = CGRectInset(rect, _borderWidth * 0.5, _borderWidth * 0.5);
    
    
    if (_unitSpace < 2) {
        UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:bounds cornerRadius:_borderRadius];
        CGContextAddPath(_ctx, bezierPath.CGPath);
        
        for (int i = 1; i < _inputUnitCount; ++i) {
            CGContextMoveToPoint(_ctx, (i * unitSize.width), 0);
            CGContextAddLineToPoint(_ctx, (i * unitSize.width), (unitSize.height));
        }
        
    } else {
        for (int i = (int)_characterArray.count; i < _inputUnitCount; i++) {
            CGRect unitRect = CGRectMake(i * (unitSize.width + _unitSpace),
                                         0,
                                         unitSize.width,
                                         unitSize.height);
            unitRect = CGRectInset(unitRect, _borderWidth * 0.5, _borderWidth * 0.5);
            UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:unitRect cornerRadius:_borderRadius];
            CGContextAddPath(_ctx, bezierPath.CGPath);
        }
    }
    CGContextDrawPath(_ctx, kCGPathStroke);
}


/**
 绘制文本
 
 当处于密文输入模式时，会用圆圈替代文本。

 @param rect 控件绘制的区域
 @param unitSize 单个 input unit 占据的尺寸
 */
- (void)_drawText:(CGRect)rect unitSize:(CGSize)unitSize {
    if ([self hasText] == NO) return;
    
    NSDictionary *attr = @{NSForegroundColorAttributeName: _textColor,
                           NSFontAttributeName: _textFont};
    
    for (int i = 0; i < _characterArray.count; i++) {
        
        CGRect unitRect = CGRectMake(i * (unitSize.width + _unitSpace),
                                     0,
                                     unitSize.width,
                                     unitSize.height);
        
        
        if (_secureTextEntry == NO) {
            NSString *subString = [_characterArray objectAtIndex:i];
            
            CGSize oneTextSize = [subString sizeWithAttributes:attr];
            CGRect drawRect = CGRectInset(unitRect,
                                   (unitRect.size.width - oneTextSize.width) / 2,
                                   (unitRect.size.height - oneTextSize.height) / 2);
            [subString drawInRect:drawRect withAttributes:attr];
        } else {
            CGRect drawRect = CGRectInset(unitRect,
                                          (unitRect.size.width - _textFont.pointSize / 2) / 2,
                                          (unitRect.size.height - _textFont.pointSize / 2) / 2);
            [_textColor setFill];
            CGContextAddEllipseInRect(_ctx, drawRect);
            CGContextFillPath(_ctx);
        }
    }
    
}


/**
 绘制跟踪框，如果指定的`trackTintColor`为 nil 则不绘制

 @param rect 控件绘制的区域
 @param unitSize 单个 input unit 占据的尺寸
 */
- (void)_drawTrackBorder:(CGRect)rect unitSize:(CGSize)unitSize {
    if (_trackTintColor == nil) return;
    if (_unitSpace < 2) return;
    
    
    [_trackTintColor setStroke];
    CGContextSetLineWidth(_ctx, _borderWidth);
    CGContextSetLineCap(_ctx, kCGLineCapRound);
    
    for (int i = 0; i < _characterArray.count; i++) {
        CGRect unitRect = CGRectMake(i * (unitSize.width + _unitSpace),
                                     0,
                                     unitSize.width,
                                     unitSize.height);
        unitRect = CGRectInset(unitRect, _borderWidth * 0.5, _borderWidth * 0.5);
        UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:unitRect cornerRadius:_borderRadius];
        CGContextAddPath(_ctx, bezierPath.CGPath);
    }
        
    CGContextDrawPath(_ctx, kCGPathStroke);
}


- (void)_resetCursorStateIfNeeded {
    _cursorLayer.hidden = !self.isFirstResponder || _cursorColor == nil || _inputUnitCount == _characterArray.count;
    
    if (_cursorLayer.hidden) return;
    
    CGSize unitSize = CGSizeMake((self.bounds.size.width + _unitSpace) / _inputUnitCount - _unitSpace, self.bounds.size.height);
    
    CGRect unitRect = CGRectMake(_characterArray.count * (unitSize.width + _unitSpace),
                                 0,
                                 unitSize.width,
                                 unitSize.height);
    unitRect = CGRectInset(unitRect,
                           unitRect.size.width / 2 - 1,
                           (unitRect.size.height - _textFont.pointSize) / 2);
    
    [CATransaction begin];
    [CATransaction setDisableActions:NO];
    [CATransaction setAnimationDuration:0];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    _cursorLayer.frame = unitRect;
    [CATransaction commit];
}


#pragma mark - UIKeyInput

- (BOOL)hasText {
    return _characterArray != nil && _characterArray.count > 0;
}


- (void)insertText:(NSString *)text {
    if (_characterArray.count >= _inputUnitCount) {
        if (_autoResignFirstResponderWhenInputFinished == YES) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self resignFirstResponder];
            }];
        }
        return;
    }
    
    if ([text isEqualToString:@" "]) {
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(unitField:shouldChangeCharactersInRange:replacementString:)]) {
        if ([self.delegate unitField:self shouldChangeCharactersInRange:NSMakeRange(_characterArray.count - 1, 1) replacementString:text] == NO) {
            return;
        }
    }
    
    NSRange range;
    for (int i = 0; i < text.length; i += range.length) {
        range = [text rangeOfComposedCharacterSequenceAtIndex:i];
        [_characterArray addObject:[text substringWithRange:range]];
    }
    
    if (_characterArray.count >= _inputUnitCount) {
        [_characterArray removeObjectsInRange:NSMakeRange(_inputUnitCount, _characterArray.count - _inputUnitCount)];
        [self sendActionsForControlEvents:UIControlEventEditingChanged];
        
        if (_autoResignFirstResponderWhenInputFinished == YES) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self resignFirstResponder];
            }];
        }
    } else {
        [self sendActionsForControlEvents:UIControlEventEditingChanged];
    }
    
    [self setNeedsDisplay];
    [self _resetCursorStateIfNeeded];
}


- (void)deleteBackward {
    if ([self hasText] == NO)
        return;
    
    if ([self.delegate respondsToSelector:@selector(unitField:shouldChangeCharactersInRange:replacementString:)]) {
        if ([self.delegate unitField:self shouldChangeCharactersInRange:NSMakeRange(_characterArray.count - 1, 0) replacementString:@""] == NO) {
            return;
        }
    }
    
    [_characterArray removeLastObject];
    [self sendActionsForControlEvents:UIControlEventEditingChanged];
    
    [self setNeedsDisplay];
    [self _resetCursorStateIfNeeded];
}


@end
