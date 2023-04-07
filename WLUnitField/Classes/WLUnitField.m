//
//  WLUnitField.m
//  WLUnitField
//
//  Created by wayne on 16/11/22.
//  Copyright © 2016年 wayne. All rights reserved.
//

#import "WLUnitField.h"
#import "WLUnitFieldTextRange.h"
#import "WLUnitFieldContentView.h"

#ifdef NSFoundationVersionNumber_iOS_9_x_Max
    NSNotificationName const WLUnitFieldDidBecomeFirstResponderNotification = @"WLUnitFieldDidBecomeFirstResponderNotification";
    NSNotificationName const WLUnitFieldDidResignFirstResponderNotification = @"WLUnitFieldDidResignFirstResponderNotification";
#else
    NSString *const WLUnitFieldDidBecomeFirstResponderNotification = @"WLUnitFieldDidBecomeFirstResponderNotification";
    NSString *const WLUnitFieldDidResignFirstResponderNotification = @"WLUnitFieldDidResignFirstResponderNotification";
#endif

@interface WLUnitField ()

@property (nonatomic) WLUnitFieldContentView *contentView;
@property (nonatomic, strong) NSMutableArray <NSString*>*characterArray;
@property (nonatomic, strong) CALayer *cursorLayer;

@end

static NSUInteger const kWLDefaultUnitCount = 4;
static NSUInteger const kWLMaximumUnitCount = 8;

@implementation WLUnitField {
    NSString *_markedText;
}

@dynamic text;
@synthesize textContentType = _textContentType;
@synthesize secureTextEntry = _secureTextEntry;
@synthesize enablesReturnKeyAutomatically = _enablesReturnKeyAutomatically;
@synthesize keyboardType = _keyboardType;
@synthesize returnKeyType = _returnKeyType;

@synthesize autocapitalizationType = _autocapitalizationType;
@synthesize autocorrectionType = _autocorrectionType;

@synthesize inputDelegate = _inputDelegate;
@synthesize selectedTextRange = _selectedTextRange;
@synthesize markedTextStyle = _markedTextStyle;

#pragma mark - Life

- (instancetype)initWithInputUnitCount:(NSUInteger)count {
    return [self initWithStyle:WLUnitFieldStyleBorder inputUnitCount:count];
}

- (instancetype)initWithStyle:(WLUnitFieldStyle)style inputUnitCount:(NSUInteger)count {
    if (self = [super initWithFrame:CGRectZero]) {
        NSCAssert(count > 0, @"WLUnitField must have one or more input units.");
        NSCAssert(count <= kWLMaximumUnitCount, @"WLUnitField input units out off bounds.");
        
        _style = style;
        _inputUnitCount = count;
        [self initialize];
    }
    
    return self;
}


- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _inputUnitCount = kWLDefaultUnitCount;
        [self initialize];
    }
    
    return self;
}


- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _inputUnitCount = kWLDefaultUnitCount;
        [self initialize];
    }
    
    return self;
}

- (void)initialize {
    self.opaque = NO;
    self.backgroundColor = [UIColor clearColor];
    
    _contentView = [[WLUnitFieldContentView alloc] initWithFrame:self.bounds];
    _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_contentView];
    
    _markedText = nil;
    _characterArray = [NSMutableArray array];
    _secureTextEntry = NO;
    _unitSpace = 12;
    _unitSize = CGSizeMake(44, 44);
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
    _autocorrectionType = UITextAutocorrectionTypeNo;
    _autocapitalizationType = UITextAutocapitalizationTypeNone;
    if (@available(iOS 12.0, *)) {
        _textContentType = UITextContentTypeOneTimeCode;
    }
    
    _cursorLayer = [CALayer layer];
    _cursorLayer.hidden = YES;
    _cursorLayer.opacity = 1;
    _cursorLayer.backgroundColor = _cursorColor.CGColor;
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
    [self.layer addSublayer:_cursorLayer];
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    if (newSuperview != nil) {
        [self _redraw];
    }
}

#pragma mark - Property

- (NSString *)text {
    if (_characterArray.count == 0) return nil;
    return [_characterArray componentsJoinedByString:@""];
}

- (void)setText:(NSString *)text {
    if ([text isEqualToString:self.text]) return;
    
    [_characterArray removeAllObjects];
    NSRange textRange = NSMakeRange(0, text.length);
    [text enumerateSubstringsInRange:textRange
                             options:NSStringEnumerationByComposedCharacterSequences
                          usingBlock:^(NSString *substring,
                                       NSRange substringRange,
                                       NSRange enclosingRange,
                                       BOOL *stop) {
        if (self.characterArray.count < self.inputUnitCount) {
            [self.characterArray addObject:substring];
        } else {
            *stop = YES;
        }
    }];
    
    // Supporting iOS12 SMS verification code, setText will be called when
    // verification code input.
    if (_characterArray.count == _inputUnitCount) {
        if (_autoResignFirstResponderWhenInputFinished == YES) {
            [self resignFirstResponder];
        }
    }
    
    [self _redraw];
}

- (void)setSecureTextEntry:(BOOL)secureTextEntry {
    _secureTextEntry = secureTextEntry;
    [self _redraw];
}

#if TARGET_INTERFACE_BUILDER
- (void)setInputUnitCount:(NSUInteger)inputUnitCount {
    inputUnitCount = MAX(1, MIN(kWLMaximumUnitCount, inputUnitCount));
    _inputUnitCount = inputUnitCount;
    [self _redraw];
}

- (void)setStyle:(NSUInteger)style {
    _style = style;
    [self _redraw];
}

#endif


- (void)setUnitSpace:(NSUInteger)unitSpace {
    if (unitSpace < 2) unitSpace = 0;
    
    _unitSpace = unitSpace;
    [self invalidateIntrinsicContentSize];
    [self _redraw];
}


- (void)setTextFont:(UIFont *)textFont {
    _textFont = textFont ?: [UIFont systemFontOfSize:22];
    [self _redraw];
}


- (void)setTextColor:(UIColor *)textColor {
    _textColor = textColor ?: [UIColor blackColor];
    [self _redraw];
}


- (void)setBorderRadius:(CGFloat)borderRadius {
    if (borderRadius < 1e-6) return;
    _borderRadius = borderRadius;
    [self _redraw];
}


- (void)setBorderWidth:(CGFloat)borderWidth {
    if (borderWidth < 1e-6) return;
    
    _borderWidth = borderWidth;
    [self _redraw];
}


- (void)setTintColor:(UIColor *)tintColor {
    _tintColor = tintColor;
    [self _redraw];
}

- (void)setTrackTintColor:(UIColor *)trackTintColor {
    _trackTintColor = trackTintColor;
    [self _redraw];
}

- (void)setCursorColor:(UIColor *)cursorColor {
    _cursorColor = cursorColor;
    _cursorLayer.backgroundColor = _cursorColor.CGColor;
    [self _resetCursorStateIfNeeded];
}

- (void)setUnitSize:(CGSize)unitSize {
    _unitSize = unitSize;
    [self invalidateIntrinsicContentSize];
    [self _redraw];
}

#pragma mark- Event

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    if (event.type == UIEventTypeTouches) {
        [self becomeFirstResponder];
    }
}

#pragma mark - Override

- (CGSize)intrinsicContentSize {
    return CGSizeMake(_inputUnitCount * (_unitSize.width + _unitSpace) - _unitSpace, _unitSize.height);
}

- (CGSize)sizeThatFits:(CGSize)size {
    return [self intrinsicContentSize];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canResignFirstResponder {
    return YES;
}

- (BOOL)becomeFirstResponder {
    BOOL result = [super becomeFirstResponder];
    [self _resetCursorStateIfNeeded];
    
    if (result ==  YES) {
        [self sendActionsForControlEvents:UIControlEventEditingDidBegin];
        [[NSNotificationCenter defaultCenter] postNotificationName:WLUnitFieldDidBecomeFirstResponderNotification object:self];
    }
    
    return result;
}

- (BOOL)resignFirstResponder {
    BOOL result = [super resignFirstResponder];
    [self _resetCursorStateIfNeeded];
    
    if (result) {
        [self sendActionsForControlEvents:UIControlEventEditingDidEnd];
        [[NSNotificationCenter defaultCenter] postNotificationName:WLUnitFieldDidResignFirstResponderNotification object:self];
    }
    
    return result;
}


//- (void)drawRect:(CGRect)rect {
//    /*
//     *  绘制的线条具有宽度，因此在绘制时需要考虑该因素对绘制效果的影响。
//     */
//    CGSize unitSize = CGSizeMake((rect.size.width + _unitSpace) / _inputUnitCount - _unitSpace, rect.size.height);
//    _ctx = UIGraphicsGetCurrentContext();
//
//    [self _fillRect:rect unitSize:unitSize];
//    [self _drawBorder:rect unitSize:unitSize];
//    [self _drawText:rect unitSize:unitSize];
//    [self _drawTrackBorder:rect unitSize:unitSize];
//}

#pragma mark- Private

- (void)_redraw {
    
}

///**
// 绘制背景色，以及剪裁绘制区域
//
// @param rect 控件绘制的区域
// */
//- (void)_fillRect:(CGRect)rect unitSize:(CGSize)unitSize {
//    [_backgroundColor setFill];
//    CGFloat radius = _style == WLUnitFieldStyleBorder ? _borderRadius : 0;
//
//    if (_unitSpace < 2) {
//        UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:radius];
//        CGContextAddPath(_ctx, bezierPath.CGPath);
//    } else {
//        for (int i = 0; i < _inputUnitCount; ++i) {
//            CGRect unitRect = CGRectMake(i * (unitSize.width + _unitSpace),
//                                         0,
//                                         unitSize.width,
//                                         unitSize.height);
//            unitRect = CGRectInset(unitRect, _borderWidth * 0.5, _borderWidth * 0.5);
//            UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:unitRect cornerRadius:radius];
//            CGContextAddPath(_ctx, bezierPath.CGPath);
//        }
//    }
//
//    CGContextFillPath(_ctx);
//}
//
//
///**
// 绘制边框
//
// 边框的绘制分为两种模式：连续和不连续。其模式的切换由`unitSpace`属性决定。
// 当`unitSpace`值小于 2 时，采用的是连续模式，即每个 input unit 之间没有间隔。
// 反之，每个 input unit 会被边框包围。
//
// @see unitSpace
//
// @param rect 控件绘制的区域
// @param unitSize 单个 input unit 占据的尺寸
// */
//- (void)_drawBorder:(CGRect)rect unitSize:(CGSize)unitSize {
//
//    CGRect bounds = CGRectInset(rect, _borderWidth * 0.5, _borderWidth * 0.5);
//
//    if (_style == WLUnitFieldStyleBorder) {
//        [self.tintColor setStroke];
//        CGContextSetLineWidth(_ctx, _borderWidth);
//        CGContextSetLineCap(_ctx, kCGLineCapRound);
//
//        if (_unitSpace < 2) {
//            UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:bounds cornerRadius:_borderRadius];
//            CGContextAddPath(_ctx, bezierPath.CGPath);
//
//            for (int i = 1; i < _inputUnitCount; ++i) {
//                CGContextMoveToPoint(_ctx, (i * unitSize.width), 0);
//                CGContextAddLineToPoint(_ctx, (i * unitSize.width), (unitSize.height));
//            }
//
//        } else {
//            for (int i = (int)_characterArray.count; i < _inputUnitCount; i++) {
//                CGRect unitRect = CGRectMake(i * (unitSize.width + _unitSpace),
//                                             0,
//                                             unitSize.width,
//                                             unitSize.height);
//                unitRect = CGRectInset(unitRect, _borderWidth * 0.5, _borderWidth * 0.5);
//                UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:unitRect cornerRadius:_borderRadius];
//                CGContextAddPath(_ctx, bezierPath.CGPath);
//            }
//        }
//
//        CGContextDrawPath(_ctx, kCGPathStroke);
//    }
//    else {
//
//        [self.tintColor setFill];
//        for (int i = (int)_characterArray.count; i < _inputUnitCount; i++) {
//            CGRect unitLineRect = CGRectMake(i * (unitSize.width + _unitSpace),
//                                         unitSize.height - _borderWidth,
//                                         unitSize.width,
//                                         _borderWidth);
//            UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:unitLineRect cornerRadius:_borderRadius];
//            CGContextAddPath(_ctx, bezierPath.CGPath);
//        }
//
//        CGContextDrawPath(_ctx, kCGPathFill);
//    }
//}
//
//
///**
// 绘制文本
//
// 当处于密文输入模式时，会用圆圈替代文本。
//
// @param rect 控件绘制的区域
// @param unitSize 单个 input unit 占据的尺寸
// */
//- (void)_drawText:(CGRect)rect unitSize:(CGSize)unitSize {
//    if ([self hasText] == NO) return;
//
//    NSDictionary *attr = @{NSForegroundColorAttributeName: _textColor,
//                           NSFontAttributeName: _textFont};
//
//    for (int i = 0; i < _characterArray.count; i++) {
//
//        CGRect unitRect = CGRectMake(i * (unitSize.width + _unitSpace),
//                                     0,
//                                     unitSize.width,
//                                     unitSize.height);
//
//        CGFloat yOffset = _style == WLUnitFieldStyleBorder ? 0 : _borderWidth;
//
//        if (_secureTextEntry == NO) {
//            NSString *subString = [_characterArray objectAtIndex:i];
//
//            CGSize oneTextSize = [subString sizeWithAttributes:attr];
//            CGRect drawRect = CGRectInset(unitRect,
//                                   (unitRect.size.width - oneTextSize.width) / 2,
//                                   (unitRect.size.height - oneTextSize.height) / 2);
//            drawRect.size.height -= yOffset;
//            [subString drawInRect:drawRect withAttributes:attr];
//        } else {
//            CGRect drawRect = CGRectInset(unitRect,
//                                          (unitRect.size.width - _textFont.pointSize / 2) / 2,
//                                          (unitRect.size.height - _textFont.pointSize / 2) / 2);
//            drawRect.size.height -= yOffset;
//            [_textColor setFill];
//            CGContextAddEllipseInRect(_ctx, drawRect);
//            CGContextFillPath(_ctx);
//        }
//    }
//
//}
//
//
///**
// 绘制跟踪框，如果指定的`trackTintColor`为 nil 则不绘制
//
// @param rect 控件绘制的区域
// @param unitSize 单个 input unit 占据的尺寸
// */
//- (void)_drawTrackBorder:(CGRect)rect unitSize:(CGSize)unitSize {
//    if (_trackTintColor == nil) return;
//
//    if (_style == WLUnitFieldStyleBorder) {
//        if (_unitSpace < 2) return;
//
//        [_trackTintColor setStroke];
//        CGContextSetLineWidth(_ctx, _borderWidth);
//        CGContextSetLineCap(_ctx, kCGLineCapRound);
//
//        for (int i = 0; i < _characterArray.count; i++) {
//            CGRect unitRect = CGRectMake(i * (unitSize.width + _unitSpace),
//                                         0,
//                                         unitSize.width,
//                                         unitSize.height);
//            unitRect = CGRectInset(unitRect, _borderWidth * 0.5, _borderWidth * 0.5);
//            UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:unitRect cornerRadius:_borderRadius];
//            CGContextAddPath(_ctx, bezierPath.CGPath);
//        }
//
//        CGContextDrawPath(_ctx, kCGPathStroke);
//    }
//    else {
//        [_trackTintColor setFill];
//
//        for (int i = 0; i < _characterArray.count; i++) {
//            CGRect unitLineRect = CGRectMake(i * (unitSize.width + _unitSpace),
//                                             unitSize.height - _borderWidth,
//                                             unitSize.width,
//                                             _borderWidth);
//            UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:unitLineRect cornerRadius:_borderRadius];
//            CGContextAddPath(_ctx, bezierPath.CGPath);
//        }
//
//        CGContextDrawPath(_ctx, kCGPathFill);
//    }
//
//}


- (void)_resetCursorStateIfNeeded {
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_cursorLayer.hidden = !self.isFirstResponder || self->_cursorColor == nil || self->_inputUnitCount == self->_characterArray.count;
        
        if (self->_cursorLayer.hidden) return;
        
        CGSize unitSize = CGSizeMake((self.bounds.size.width + self->_unitSpace) / self->_inputUnitCount - self->_unitSpace, self.bounds.size.height);
        
        CGRect unitRect = CGRectMake(self->_characterArray.count * (unitSize.width + self->_unitSpace),
                                     0,
                                     unitSize.width,
                                     unitSize.height);
        unitRect = CGRectInset(unitRect,
                               unitRect.size.width / 2 - 1,
                               (unitRect.size.height - self->_textFont.pointSize) / 2);
        
        CGFloat yOffset = self->_style == WLUnitFieldStyleBorder ? 0 : self->_borderWidth;
        unitRect.size.height -= yOffset;
        
        [CATransaction begin];
        [CATransaction setDisableActions:NO];
        [CATransaction setAnimationDuration:0];
        [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        self->_cursorLayer.frame = unitRect;
        [CATransaction commit];
    });
}


#pragma mark - UIKeyInput

- (BOOL)hasText {
    return _characterArray != nil && _characterArray.count > 0;
}

- (void)insertText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [self resignFirstResponder];
        return;
    }
    if ([text isEqualToString:@" "]) {
        return;
    }
    if (_characterArray.count >= _inputUnitCount) {
        if (_autoResignFirstResponderWhenInputFinished == YES && self.isFirstResponder) {
            [self resignFirstResponder];
        }
        return;
    }
    if ([self.delegate respondsToSelector:@selector(unitField:shouldChangeCharactersInRange:replacementString:)]) {
        NSRange range = NSMakeRange(self.text.length, text.length);
        if ([self.delegate unitField:self shouldChangeCharactersInRange:range replacementString:text] == NO) {
            return;
        }
    }
    
    [_inputDelegate textWillChange:self];
    NSRange range;
    for (int i = 0; i < text.length; i += range.length) {
        range = [text rangeOfComposedCharacterSequenceAtIndex:i];
        [_characterArray addObject:[text substringWithRange:range]];
    }
    
    if (_characterArray.count >= _inputUnitCount) {
        [_characterArray removeObjectsInRange:NSMakeRange(_inputUnitCount, _characterArray.count - _inputUnitCount)];
        [self _redraw];
        [self sendActionsForControlEvents:UIControlEventEditingChanged];
        if (_autoResignFirstResponderWhenInputFinished == YES) {
            [self resignFirstResponder];
        }
    } else {
        [self sendActionsForControlEvents:UIControlEventEditingChanged];
    }
    [_inputDelegate textDidChange:self];
}

- (void)deleteBackward {
    if ([self hasText] == NO) return;
    
    [_inputDelegate textWillChange:self];
    [_characterArray removeLastObject];
    [self _redraw];
    [self sendActionsForControlEvents:UIControlEventEditingChanged];
    [_inputDelegate textDidChange:self];
}

// UITextInput implemention.
#pragma mark - UITextInput

/* Methods for manipulating text. */
- (nullable NSString *)textInRange:(WLUnitFieldTextRange *)range {
    return nil;
}

- (void)replaceRange:(WLUnitFieldTextRange *)range withText:(NSString *)text { }

// selectedRange is a range within the markedText
- (void)setMarkedText:(nullable NSString *)markedText selectedRange:(NSRange)selectedRange {
    _markedText = [markedText copy];
}

- (void)unmarkText {
    if (self.text.length >= self.inputUnitCount)
        return;
    
    if (_markedText == nil)
        return;
    
    [self insertText:_markedText];
}

/* The end and beginning of the the text document. */
- (UITextPosition *)beginningOfDocument {
    return [WLUnitFieldTextPosition positionWithOffset:0];
}

- (UITextPosition *)endOfDocument {
    return [WLUnitFieldTextPosition positionWithOffset:self.text.length - 1];
}

/* A tokenizer must be provided to inform the text input system about text units of varying granularity. */
- (id<UITextInputTokenizer>)tokenizer {
    return [[UITextInputStringTokenizer alloc] initWithTextInput:self];
}

// Nil if no marked text.
- (UITextRange *)markedTextRange { return nil; }

/* Methods for creating ranges and positions. */
- (nullable UITextRange *)textRangeFromPosition:(WLUnitFieldTextPosition *)fromPosition toPosition:(WLUnitFieldTextPosition *)toPosition {
    return [WLUnitFieldTextRange rangeWithStart:fromPosition end:toPosition];
}

- (nullable UITextPosition *)positionFromPosition:(WLUnitFieldTextPosition *)position offset:(NSInteger)offset {
    return [WLUnitFieldTextPosition positionWithOffset:position.offset + offset];
}

- (nullable UITextPosition *)positionFromPosition:(WLUnitFieldTextPosition *)position inDirection:(UITextLayoutDirection)direction offset:(NSInteger)offset {
    return [WLUnitFieldTextPosition positionWithOffset:position.offset + offset];
}

/* Simple evaluation of positions */
- (NSComparisonResult)comparePosition:(WLUnitFieldTextPosition *)position toPosition:(WLUnitFieldTextPosition *)other {
    if (position.offset < other.offset) return NSOrderedAscending;
    if (position.offset > other.offset) return NSOrderedDescending;
    return NSOrderedSame;
}

- (NSInteger)offsetFromPosition:(WLUnitFieldTextPosition *)from toPosition:(WLUnitFieldTextPosition *)toPosition {
    return toPosition.offset - from.offset ;
}

/* Layout questions. */
- (nullable UITextPosition *)positionWithinRange:(UITextRange *)range farthestInDirection:(UITextLayoutDirection)direction {
    return nil;
}

- (nullable UITextRange *)characterRangeByExtendingPosition:(WLUnitFieldTextPosition *)position inDirection:(UITextLayoutDirection)direction {
    return nil;
}

/* Writing direction */
- (UITextWritingDirection)baseWritingDirectionForPosition:(WLUnitFieldTextPosition *)position inDirection:(UITextStorageDirection)direction {
    return UITextWritingDirectionNatural;
}

- (void)setBaseWritingDirection:(UITextWritingDirection)writingDirection forRange:(UITextRange *)range {
}

/* Geometry used to provide, for example, a correction rect. */
- (NSArray<UITextSelectionRect *> *)selectionRectsForRange:(WLUnitFieldTextRange *)range {
    return nil;
}

- (CGRect)firstRectForRange:(WLUnitFieldTextRange *)range {
    return CGRectNull;
}

- (CGRect)caretRectForPosition:(WLUnitFieldTextPosition *)position {
    return CGRectNull;
}

/* Hit testing. */
- (nullable UITextRange *)characterRangeAtPoint:(CGPoint)point {
    return nil;
}

- (nullable UITextPosition *)closestPositionToPoint:(CGPoint)point withinRange:(WLUnitFieldTextRange *)range {
    return nil;
}

- (nullable UITextPosition *)closestPositionToPoint:(CGPoint)point {
    return nil;
}

@end
