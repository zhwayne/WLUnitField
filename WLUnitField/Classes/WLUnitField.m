//
//  WLUnitField.m
//  WLUnitField
//
//  Created by wayne on 16/11/22.
//  Copyright © 2016年 wayne. All rights reserved.
//

#import "WLUnitField.h"

#ifdef NSFoundationVersionNumber_iOS_9_x_Max
NSNotificationName const WLUnitFieldDidBecomeFirstResponderNotification =
    @"WLUnitFieldDidBecomeFirstResponderNotification";
NSNotificationName const WLUnitFieldDidResignFirstResponderNotification =
    @"WLUnitFieldDidResignFirstResponderNotification";
#else
NSString *const WLUnitFieldDidBecomeFirstResponderNotification =
    @"WLUnitFieldDidBecomeFirstResponderNotification";
NSString *const WLUnitFieldDidResignFirstResponderNotification =
    @"WLUnitFieldDidResignFirstResponderNotification";
#endif

// UITextInput 辅助类 - 必须在 WLUnitField 之前定义
@interface WLUnitFieldTextPosition : UITextPosition
@property(nonatomic, assign) NSInteger offset;
+ (instancetype)positionWithOffset:(NSInteger)offset;
@end

@implementation WLUnitFieldTextPosition
+ (instancetype)positionWithOffset:(NSInteger)offset {
  WLUnitFieldTextPosition *pos = [[WLUnitFieldTextPosition alloc] init];
  pos.offset = offset;
  return pos;
}
@end

@interface WLUnitFieldTextRange : UITextRange
@property(nonatomic, assign) NSInteger startOffset;
@property(nonatomic, assign) NSInteger endOffset;
+ (instancetype)rangeWithStart:(NSInteger)start end:(NSInteger)end;
@end

@implementation WLUnitFieldTextRange
+ (instancetype)rangeWithStart:(NSInteger)start end:(NSInteger)end {
  WLUnitFieldTextRange *range = [[WLUnitFieldTextRange alloc] init];
  range.startOffset = start;
  range.endOffset = end;
  return range;
}

- (UITextPosition *)start {
  return [WLUnitFieldTextPosition positionWithOffset:self.startOffset];
}

- (UITextPosition *)end {
  return [WLUnitFieldTextPosition positionWithOffset:self.endOffset];
}

- (BOOL)isEmpty {
  return self.startOffset == self.endOffset;
}
@end

@interface WLUnitField ()

@property(nonatomic, strong) NSMutableArray<NSString *> *characterArray;
@property(nonatomic, strong) CALayer *cursorLayer;
@property(nonatomic, strong) UIColor *internalBackgroundColor;

@end

@implementation WLUnitField {
  NSString *mMarkedText;
  id _inputDelegate;
}

@dynamic text;
@synthesize textContentType = _textContentType;
@synthesize secureTextEntry = _secureTextEntry;
@synthesize enablesReturnKeyAutomatically = _enablesReturnKeyAutomatically;
@synthesize keyboardType = _keyboardType;
@synthesize returnKeyType = _returnKeyType;

@synthesize autocapitalizationType = _autocapitalizationType;
@synthesize autocorrectionType = _autocorrectionType;

#pragma mark - Life

- (instancetype)initWithInputUnitCount:(NSUInteger)count {
  return [self initWithStyle:WLUnitFieldStyleBorder inputUnitCount:count];
}

- (instancetype)initWithStyle:(WLUnitFieldStyle)style
               inputUnitCount:(NSUInteger)count {
  if (self = [super initWithFrame:CGRectZero]) {
    NSCAssert(count > 0, @"WLUnitField must have one or more input units.");
    NSCAssert(count <= 8, @"WLUnitField can not have more than 8 input units.");

    _style = style;
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
  _unitSize = CGSizeMake(44, 44);
  _borderRadius = 0;
  _borderWidth = 1;
  _textFont = [UIFont systemFontOfSize:22];
  _keyboardType = UIKeyboardTypeNumberPad;
  _returnKeyType = UIReturnKeyDone;
  _enablesReturnKeyAutomatically = YES;
  _autoResignFirstResponderWhenInputFinished = NO;
  _showsCursor = YES;
  _textColor = [UIColor darkGrayColor];
  _strokeColor = [UIColor lightGrayColor];
  _trackTintColor = [UIColor orangeColor];
  _internalBackgroundColor = [UIColor clearColor];
  _allowedCharacterSet = nil; // 默认允许所有字符
  _autocorrectionType = UITextAutocorrectionTypeNo;
  _autocapitalizationType = UITextAutocapitalizationTypeNone;

  [self updateCursorColor];

  _textContentType = UITextContentTypeOneTimeCode;

  [self.layer addSublayer:self.cursorLayer];
  [self setupAccessibility];
  [self setNeedsDisplay];
}

#pragma mark - Property

- (NSString *)text {
  if (_characterArray.count == 0)
    return nil;
  return [_characterArray componentsJoinedByString:@""];
}

- (void)setText:(NSString *)text {

  [_characterArray removeAllObjects];
  [text
      enumerateSubstringsInRange:NSMakeRange(0, text.length)
                         options:NSStringEnumerationByComposedCharacterSequences
                      usingBlock:^(
                          NSString *_Nullable substring, NSRange substringRange,
                          NSRange enclosingRange, BOOL *_Nonnull stop) {
                        if (self.characterArray.count < self.inputUnitCount)
                          [self.characterArray addObject:substring];
                        else
                          *stop = YES;
                      }];

  [self setNeedsDisplay];
  [self _resetCursorStateIfNeeded];

  /**
   Supporting iOS12 SMS verification code, setText will be called when
   verification code input.
   */
  if (_characterArray.count >= _inputUnitCount) {
    if (_autoResignFirstResponderWhenInputFinished == YES) {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self resignFirstResponder];
      }];
    }
    return;
  }
}

- (CALayer *)cursorLayer {
  if (!_cursorLayer) {
    _cursorLayer = [CALayer layer];
    _cursorLayer.hidden = YES;
    _cursorLayer.opacity = 1;

    mMarkedText = nil;

    // 优化动画性能，避免无限循环
    [self _startCursorAnimation];

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      [self layoutIfNeeded];

      self.cursorLayer.position =
          CGPointMake(CGRectGetWidth(self.bounds) / self.inputUnitCount / 2,
                      CGRectGetHeight(self.bounds) / 2);
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

- (void)setStyle:(NSUInteger)style {
  _style = style;
  [self setNeedsDisplay];
  [self _resetCursorStateIfNeeded];
}

#endif

- (void)setUnitSpace:(NSUInteger)unitSpace {
  if (unitSpace < 2)
    unitSpace = 0;

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
    textColor = [UIColor blackColor];
  }

  // 避免不必要的重绘
  if ([_textColor isEqual:textColor])
    return;

  _textColor = textColor;
  [self setNeedsDisplay];
  [self _resetCursorStateIfNeeded];
}

- (void)setBorderRadius:(CGFloat)borderRadius {
  if (borderRadius < 0)
    return;

  _borderRadius = borderRadius;
  [self setNeedsDisplay];
  [self _resetCursorStateIfNeeded];
}

- (void)setBorderWidth:(CGFloat)borderWidth {
  if (borderWidth < 0)
    return;

  _borderWidth = borderWidth;
  [self setNeedsDisplay];
  [self _resetCursorStateIfNeeded];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
  _internalBackgroundColor = backgroundColor;
  [super setBackgroundColor:backgroundColor];
  [self setNeedsDisplay];
  [self _resetCursorStateIfNeeded];
}

- (void)setStrokeColor:(UIColor *)strokeColor {
  // 避免不必要的重绘
  if ([_strokeColor isEqual:strokeColor])
    return;

  _strokeColor = strokeColor;
  [self setNeedsDisplay];
  [self _resetCursorStateIfNeeded];
}

- (void)setTrackTintColor:(UIColor *)trackTintColor {
  // 避免不必要的重绘
  if ([_trackTintColor isEqual:trackTintColor])
    return;

  _trackTintColor = trackTintColor;
  [self setNeedsDisplay];
  [self _resetCursorStateIfNeeded];
}

- (void)setUnitSize:(CGSize)unitSize {
  _unitSize = unitSize;
  [self setNeedsDisplay];
  [self _resetCursorStateIfNeeded];
}

- (void)setTintColor:(UIColor *)tintColor {
  [super setTintColor:tintColor];
  [self updateCursorColor];
}

- (void)updateCursorColor {
  self.cursorLayer.backgroundColor = self.tintColor.CGColor;
  [self _resetCursorStateIfNeeded];
}

- (void)setShowsCursor:(BOOL)showsCursor {
  _showsCursor = showsCursor;
  [self _resetCursorStateIfNeeded];
}

#pragma mark - Event

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  [super touchesBegan:touches withEvent:event];
  [self becomeFirstResponder];
}

#pragma mark - Override

- (CGSize)intrinsicContentSize {

  return CGSizeMake(_inputUnitCount * (_unitSize.width + _unitSpace) -
                        _unitSpace,
                    _unitSize.height);
}

- (CGSize)sizeThatFits:(CGSize)size {
  CGSize intrinsicSize = [self intrinsicContentSize];

  // 如果传入的尺寸足够大，返回固有尺寸
  if (size.width >= intrinsicSize.width &&
      size.height >= intrinsicSize.height) {
    return intrinsicSize;
  }

  // 如果传入的尺寸太小，返回传入的尺寸（但至少保证最小尺寸）
  CGSize minSize = CGSizeMake(_inputUnitCount * 20, 20); // 最小尺寸
  return CGSizeMake(MAX(size.width, minSize.width),
                    MAX(size.height, minSize.height));
}

- (BOOL)canBecomeFirstResponder {
  return YES;
}

- (BOOL)becomeFirstResponder {
  BOOL result = [super becomeFirstResponder];
  [self _resetCursorStateIfNeeded];

  if (result == YES) {
    [self sendActionsForControlEvents:UIControlEventEditingDidBegin];
    [[NSNotificationCenter defaultCenter]
        postNotificationName:WLUnitFieldDidBecomeFirstResponderNotification
                      object:nil];
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
    [[NSNotificationCenter defaultCenter]
        postNotificationName:WLUnitFieldDidResignFirstResponderNotification
                      object:nil];
  }

  return result;
}

- (void)drawRect:(CGRect)rect {
  /*
   *  绘制的线条具有宽度，因此在绘制时需要考虑该因素对绘制效果的影响。
   */
  CGSize unitSize =
      CGSizeMake((rect.size.width + _unitSpace) / _inputUnitCount - _unitSpace,
                 rect.size.height);
  CGContextRef ctx = UIGraphicsGetCurrentContext();

  [self _fillRect:rect unitSize:unitSize context:ctx];
  [self _drawBorder:rect unitSize:unitSize context:ctx];
  [self _drawText:rect unitSize:unitSize context:ctx];
  [self _drawTrackBorder:rect unitSize:unitSize context:ctx];
}

#pragma mark - Private

/**
 在 AutoLayout 环境下重新指定控件本身的固有尺寸

 `-drawRect:`方法会计算控件完成自身的绘制所需的合适尺寸，完成一次绘制后会通知
 AutoLayout 系统更新尺寸。
 */
- (void)_resize {
  [self invalidateIntrinsicContentSize];
}

/**
 绘制背景色，以及剪裁绘制区域

 @param rect 控件绘制的区域
 */
- (void)_fillRect:(CGRect)rect
         unitSize:(CGSize)unitSize
          context:(CGContextRef)ctx {
  [_internalBackgroundColor setFill];
  CGFloat radius = _style == WLUnitFieldStyleBorder ? _borderRadius : 0;

  if (_unitSpace < 2) {
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:rect
                                                          cornerRadius:radius];
    CGContextAddPath(ctx, bezierPath.CGPath);
  } else {
    for (int i = 0; i < _inputUnitCount; ++i) {
      CGRect unitRect = CGRectMake(i * (unitSize.width + _unitSpace), 0,
                                   unitSize.width, unitSize.height);
      unitRect = CGRectInset(unitRect, _borderWidth * 0.5, _borderWidth * 0.5);
      UIBezierPath *bezierPath =
          [UIBezierPath bezierPathWithRoundedRect:unitRect cornerRadius:radius];
      CGContextAddPath(ctx, bezierPath.CGPath);
    }
  }

  CGContextFillPath(ctx);
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
- (void)_drawBorder:(CGRect)rect
           unitSize:(CGSize)unitSize
            context:(CGContextRef)ctx {

  CGRect bounds = CGRectInset(rect, _borderWidth * 0.5, _borderWidth * 0.5);

  if (_style == WLUnitFieldStyleBorder) {
    [self.strokeColor setStroke];
    CGContextSetLineWidth(ctx, _borderWidth);
    CGContextSetLineCap(ctx, kCGLineCapRound);

    if (_unitSpace < 2) {
      UIBezierPath *bezierPath =
          [UIBezierPath bezierPathWithRoundedRect:bounds
                                     cornerRadius:_borderRadius];
      CGContextAddPath(ctx, bezierPath.CGPath);

      for (int i = 1; i < _inputUnitCount; ++i) {
        CGContextMoveToPoint(ctx, (i * unitSize.width), 0);
        CGContextAddLineToPoint(ctx, (i * unitSize.width), (unitSize.height));
      }

    } else {
      for (int i = (int)_characterArray.count; i < _inputUnitCount; i++) {
        CGRect unitRect = CGRectMake(i * (unitSize.width + _unitSpace), 0,
                                     unitSize.width, unitSize.height);
        unitRect =
            CGRectInset(unitRect, _borderWidth * 0.5, _borderWidth * 0.5);
        UIBezierPath *bezierPath =
            [UIBezierPath bezierPathWithRoundedRect:unitRect
                                       cornerRadius:_borderRadius];
        CGContextAddPath(ctx, bezierPath.CGPath);
      }
    }

    CGContextDrawPath(ctx, kCGPathStroke);
  } else {

    [self.strokeColor setFill];
    for (int i = (int)_characterArray.count; i < _inputUnitCount; i++) {
      CGRect unitLineRect = CGRectMake(i * (unitSize.width + _unitSpace),
                                       unitSize.height - _borderWidth,
                                       unitSize.width, _borderWidth);
      UIBezierPath *bezierPath =
          [UIBezierPath bezierPathWithRoundedRect:unitLineRect
                                     cornerRadius:_borderRadius];
      CGContextAddPath(ctx, bezierPath.CGPath);
    }

    CGContextDrawPath(ctx, kCGPathFill);
  }
}

/**
 绘制文本

 当处于密文输入模式时，会用圆圈替代文本。

 @param rect 控件绘制的区域
 @param unitSize 单个 input unit 占据的尺寸
 */
- (void)_drawText:(CGRect)rect
         unitSize:(CGSize)unitSize
          context:(CGContextRef)ctx {
  if ([self hasText] == NO)
    return;

  NSDictionary *attr = @{
    NSForegroundColorAttributeName : _textColor,
    NSFontAttributeName : _textFont
  };

  for (int i = 0; i < _characterArray.count; i++) {

    CGRect unitRect = CGRectMake(i * (unitSize.width + _unitSpace), 0,
                                 unitSize.width, unitSize.height);

    CGFloat yOffset = _style == WLUnitFieldStyleBorder ? 0 : _borderWidth;

    if (_secureTextEntry == NO) {
      NSString *subString = [_characterArray objectAtIndex:i];

      CGSize oneTextSize = [subString sizeWithAttributes:attr];
      CGRect drawRect =
          CGRectInset(unitRect, (unitRect.size.width - oneTextSize.width) / 2,
                      (unitRect.size.height - oneTextSize.height) / 2);
      drawRect.size.height -= yOffset;
      [subString drawInRect:drawRect withAttributes:attr];
    } else {
      CGRect drawRect = CGRectInset(
          unitRect, (unitRect.size.width - _textFont.pointSize / 2) / 2,
          (unitRect.size.height - _textFont.pointSize / 2) / 2);
      drawRect.size.height -= yOffset;
      [_textColor setFill];
      CGContextAddEllipseInRect(ctx, drawRect);
      CGContextFillPath(ctx);
    }
  }
}

/**
 绘制跟踪框，如果指定的`trackTintColor`为 nil 则不绘制

 @param rect 控件绘制的区域
 @param unitSize 单个 input unit 占据的尺寸
 */
- (void)_drawTrackBorder:(CGRect)rect
                unitSize:(CGSize)unitSize
                 context:(CGContextRef)ctx {
  if (_trackTintColor == nil)
    return;

  if (_style == WLUnitFieldStyleBorder) {
    if (_unitSpace < 2)
      return;

    [_trackTintColor setStroke];
    CGContextSetLineWidth(ctx, _borderWidth);
    CGContextSetLineCap(ctx, kCGLineCapRound);

    for (int i = 0; i < _characterArray.count; i++) {
      CGRect unitRect = CGRectMake(i * (unitSize.width + _unitSpace), 0,
                                   unitSize.width, unitSize.height);
      unitRect = CGRectInset(unitRect, _borderWidth * 0.5, _borderWidth * 0.5);
      UIBezierPath *bezierPath =
          [UIBezierPath bezierPathWithRoundedRect:unitRect
                                     cornerRadius:_borderRadius];
      CGContextAddPath(ctx, bezierPath.CGPath);
    }

    CGContextDrawPath(ctx, kCGPathStroke);
  } else {
    [_trackTintColor setFill];

    for (int i = 0; i < _characterArray.count; i++) {
      CGRect unitLineRect = CGRectMake(i * (unitSize.width + _unitSpace),
                                       unitSize.height - _borderWidth,
                                       unitSize.width, _borderWidth);
      UIBezierPath *bezierPath =
          [UIBezierPath bezierPathWithRoundedRect:unitLineRect
                                     cornerRadius:_borderRadius];
      CGContextAddPath(ctx, bezierPath.CGPath);
    }

    CGContextDrawPath(ctx, kCGPathFill);
  }
}

- (void)_startCursorAnimation {
  // 避免重复添加动画
  if (_cursorLayer.animationKeys.count > 0)
    return;

  CABasicAnimation *animate =
      [CABasicAnimation animationWithKeyPath:@"opacity"];
  animate.fromValue = @(0);
  animate.toValue = @(1.5);
  animate.duration = 0.5;
  animate.timingFunction = [CAMediaTimingFunction
      functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
  animate.autoreverses = YES;
  animate.removedOnCompletion = NO;
  animate.fillMode = kCAFillModeForwards;
  animate.repeatCount = HUGE_VALF;

  [_cursorLayer addAnimation:animate forKey:@"cursorBlink"];
}

- (void)setupAccessibility {
  self.isAccessibilityElement = YES;
  self.accessibilityTraits = UIAccessibilityTraitKeyboardKey;
  self.accessibilityLabel = @"验证码输入框";
  [self updateAccessibilityValue];
}

- (void)updateAccessibilityValue {
  NSString *value =
      [NSString stringWithFormat:@"已输入 %lu 位，共 %lu 位",
                                 (unsigned long)self.characterArray.count,
                                 (unsigned long)self.inputUnitCount];
  self.accessibilityValue = value;
}

- (BOOL)isValidInput:(NSString *)text {
  if (!text || text.length == 0)
    return NO;

  // 检查是否只包含允许的字符
  NSCharacterSet *invertedSet = [_allowedCharacterSet invertedSet];
  return [text rangeOfCharacterFromSet:invertedSet].location == NSNotFound;
}

- (void)showInputError {
  // 简单的错误反馈：震动效果
  UIImpactFeedbackGenerator *feedbackGenerator =
      [[UIImpactFeedbackGenerator alloc]
          initWithStyle:UIImpactFeedbackStyleLight];
  [feedbackGenerator impactOccurred];

  // 可以添加更多错误处理逻辑，如显示错误提示等
  NSLog(@"WLUnitField: 无效输入");
}

#pragma mark - Helper Methods

- (CGRect)unitRectForIndex:(NSInteger)index unitSize:(CGSize)unitSize {
  return CGRectMake(index * (unitSize.width + _unitSpace), 0, unitSize.width,
                    unitSize.height);
}

- (void)performUIUpdate:(void (^)(void))updateBlock {
  dispatch_async(dispatch_get_main_queue(), ^{
    if (updateBlock) {
      updateBlock();
    }
  });
}

- (void)scheduleRedraw {
  [self setNeedsDisplay];
  [self _resetCursorStateIfNeeded];
  [self updateAccessibilityValue];
}

- (void)_resetCursorStateIfNeeded {
  // 直接在主线程执行，对于验证码输入框来说足够简单
  BOOL shouldHide = !self.isFirstResponder || !self->_showsCursor ||
                    self.tintColor == nil ||
                    self->_inputUnitCount == self->_characterArray.count;

  self->_cursorLayer.hidden = shouldHide;

  if (self->_cursorLayer.hidden)
    return;

  CGSize unitSize = CGSizeMake((self.bounds.size.width + self->_unitSpace) /
                                       self->_inputUnitCount -
                                   self->_unitSpace,
                               self.bounds.size.height);

  CGRect unitRect = CGRectMake(self->_characterArray.count *
                                   (unitSize.width + self->_unitSpace),
                               0, unitSize.width, unitSize.height);
  unitRect =
      CGRectInset(unitRect, unitRect.size.width / 2 - 1,
                  (unitRect.size.height - self->_textFont.pointSize) / 2);

  CGFloat yOffset =
      self->_style == WLUnitFieldStyleBorder ? 0 : self->_borderWidth;
  unitRect.size.height -= yOffset;

  [CATransaction begin];
  [CATransaction setDisableActions:NO];
  [CATransaction setAnimationDuration:0];
  [CATransaction setAnimationTimingFunction:
                     [CAMediaTimingFunction
                         functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
  self->_cursorLayer.frame = unitRect;
  [CATransaction commit];
}

#pragma mark - UIKeyInput & UITextInput

/**
 Supporting iOS12 SMS verification code, keyboardType must be
 UIKeyboardTypeNumberPad to localizable.

 Must set textContentType to UITextContentTypeOneTimeCode
 */

#pragma mark - UITextInput (Minimal implementation for autofill only)

// 只实现自动填充所需的最少方法，不支持文本选择

- (UITextRange *)selectedTextRange {
  // 返回一个固定的空范围，不支持选择
  NSInteger length = (NSInteger)self.text.length;
  return [WLUnitFieldTextRange rangeWithStart:length end:length];
}

- (void)setSelectedTextRange:(UITextRange *)selectedTextRange {
  // 不支持设置选择范围
}

- (UITextRange *)markedTextRange {
  return nil;
}

- (NSDictionary<NSAttributedStringKey, id> *)markedTextStyle {
  return nil;
}

- (void)setMarkedTextStyle:
    (NSDictionary<NSAttributedStringKey, id> *)markedTextStyle {
}

- (UITextPosition *)beginningOfDocument {
  return [WLUnitFieldTextPosition positionWithOffset:0];
}

- (UITextPosition *)endOfDocument {
  return
      [WLUnitFieldTextPosition positionWithOffset:(NSInteger)self.text.length];
}

- (id)inputDelegate {
  return _inputDelegate;
}

- (void)setInputDelegate:(id)inputDelegate {
  _inputDelegate = inputDelegate;
}

- (UIView *)textInputView {
  return self;
}

- (id<UITextInputTokenizer>)tokenizer {
  // 返回系统默认的 tokenizer，用于文本边界识别
  // 对于验证码输入框，使用默认实现即可
  static UITextInputStringTokenizer *defaultTokenizer = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    defaultTokenizer =
        [[UITextInputStringTokenizer alloc] initWithTextInput:self];
  });
  return defaultTokenizer;
}

- (UITextInputMode *)textInputMode {
  // 返回当前键盘输入模式，这对于验证码自动填充很重要
  NSArray<UITextInputMode *> *inputModes = [UITextInputMode activeInputModes];
  if (inputModes.count > 0) {
    return inputModes.firstObject;
  }
  return nil;
}

// 以下方法只返回简单的默认值，不支持文本选择功能
- (UITextRange *)textRangeFromPosition:(UITextPosition *)fromPosition
                            toPosition:(UITextPosition *)toPosition {
  WLUnitFieldTextPosition *start = (WLUnitFieldTextPosition *)fromPosition;
  WLUnitFieldTextPosition *end = (WLUnitFieldTextPosition *)toPosition;
  return [WLUnitFieldTextRange rangeWithStart:start.offset end:end.offset];
}

- (UITextPosition *)positionFromPosition:(UITextPosition *)position
                                  offset:(NSInteger)offset {
  WLUnitFieldTextPosition *pos = (WLUnitFieldTextPosition *)position;
  NSInteger newOffset = pos.offset + offset;
  newOffset = MAX(0, MIN(newOffset, (NSInteger)self.text.length));
  return [WLUnitFieldTextPosition positionWithOffset:newOffset];
}

- (UITextPosition *)positionFromPosition:(UITextPosition *)position
                             inDirection:(UITextLayoutDirection)direction
                                  offset:(NSInteger)offset {
  return [self positionFromPosition:position offset:offset];
}

- (NSComparisonResult)comparePosition:(UITextPosition *)position
                           toPosition:(UITextPosition *)other {
  WLUnitFieldTextPosition *pos1 = (WLUnitFieldTextPosition *)position;
  WLUnitFieldTextPosition *pos2 = (WLUnitFieldTextPosition *)other;
  if (pos1.offset < pos2.offset)
    return NSOrderedAscending;
  if (pos1.offset > pos2.offset)
    return NSOrderedDescending;
  return NSOrderedSame;
}

- (NSInteger)offsetFromPosition:(UITextPosition *)from
                     toPosition:(UITextPosition *)toPosition {
  WLUnitFieldTextPosition *fromPos = (WLUnitFieldTextPosition *)from;
  WLUnitFieldTextPosition *toPos = (WLUnitFieldTextPosition *)toPosition;
  return toPos.offset - fromPos.offset;
}

- (UITextPosition *)positionWithinRange:(UITextRange *)range
                    farthestInDirection:(UITextLayoutDirection)direction {
  WLUnitFieldTextRange *r = (WLUnitFieldTextRange *)range;
  return direction == UITextLayoutDirectionLeft ||
                 direction == UITextLayoutDirectionUp
             ? [WLUnitFieldTextPosition positionWithOffset:r.startOffset]
             : [WLUnitFieldTextPosition positionWithOffset:r.endOffset];
}

- (UITextRange *)characterRangeByExtendingPosition:(UITextPosition *)position
                                       inDirection:
                                           (UITextLayoutDirection)direction {
  WLUnitFieldTextPosition *pos = (WLUnitFieldTextPosition *)position;
  NSInteger offset = pos.offset;
  if (direction == UITextLayoutDirectionLeft ||
      direction == UITextLayoutDirectionUp) {
    return [WLUnitFieldTextRange rangeWithStart:MAX(0, offset - 1) end:offset];
  } else {
    return [WLUnitFieldTextRange
        rangeWithStart:offset
                   end:MIN((NSInteger)self.text.length, offset + 1)];
  }
}

- (UITextWritingDirection)
    baseWritingDirectionForPosition:(UITextPosition *)position
                        inDirection:(UITextStorageDirection)direction {
  return UITextWritingDirectionNatural;
}

- (void)setBaseWritingDirection:(UITextWritingDirection)writingDirection
                       forRange:(UITextRange *)range {
}

- (CGRect)firstRectForRange:(UITextRange *)range {
  return self.bounds;
}

- (CGRect)caretRectForPosition:(UITextPosition *)position {
  return self.bounds;
}

- (NSArray<UITextSelectionRect *> *)selectionRectsForRange:
    (UITextRange *)range {
  return @[];
}

- (UITextPosition *)closestPositionToPoint:(CGPoint)point {
  return [self endOfDocument];
}

- (UITextPosition *)closestPositionToPoint:(CGPoint)point
                               withinRange:(UITextRange *)range {
  return [self endOfDocument];
}

- (UITextRange *)characterRangeAtPoint:(CGPoint)point {
  // 对于验证码输入框，返回整个文本范围
  NSInteger length = (NSInteger)self.text.length;
  if (length > 0) {
    return [WLUnitFieldTextRange rangeWithStart:0 end:length];
  }
  return [WLUnitFieldTextRange rangeWithStart:0 end:0];
}

- (void)setMarkedText:(NSString *)markedText
        selectedRange:(NSRange)selectedRange {
  mMarkedText = markedText;
}

- (void)unmarkText {
  mMarkedText = nil;
}

- (NSString *)textInRange:(UITextRange *)range {
  WLUnitFieldTextRange *r = (WLUnitFieldTextRange *)range;
  NSInteger start = MAX(0, MIN(r.startOffset, (NSInteger)self.text.length));
  NSInteger end = MAX(0, MIN(r.endOffset, (NSInteger)self.text.length));
  if (start >= end)
    return @"";
  return [self.text substringWithRange:NSMakeRange(start, end - start)];
}

- (void)replaceRange:(UITextRange *)range withText:(NSString *)text {
  // 简化实现：直接使用 insertText
  if (text.length > 0) {
    [self insertText:text];
  }
}

- (NSDictionary<NSAttributedStringKey, id> *)
    textStylingAtPosition:(UITextPosition *)position
              inDirection:(UITextStorageDirection)direction {
  return @{};
}

- (UITextRange *)textRangeOfWordAtPosition:(UITextPosition *)position {
  // 对于验证码输入框，每个字符都是独立的"单词"
  WLUnitFieldTextPosition *pos = (WLUnitFieldTextPosition *)position;
  NSInteger offset = pos.offset;
  NSInteger length = (NSInteger)self.text.length;

  // 如果位置在文本范围内，返回单个字符的范围
  if (offset >= 0 && offset < length) {
    return [WLUnitFieldTextRange rangeWithStart:offset end:offset + 1];
  }
  // 否则返回文档末尾的空范围
  return [WLUnitFieldTextRange rangeWithStart:length end:length];
}

- (UITextRange *)textRangeOfSentenceAtPosition:(UITextPosition *)position {
  // 对于验证码输入框，整个文本就是一个"句子"
  NSInteger length = (NSInteger)self.text.length;
  return [WLUnitFieldTextRange rangeWithStart:0 end:length];
}

- (UITextRange *)textRangeOfParagraphAtPosition:(UITextPosition *)position {
  // 对于验证码输入框，整个文本就是一个"段落"
  NSInteger length = (NSInteger)self.text.length;
  return [WLUnitFieldTextRange rangeWithStart:0 end:length];
}

- (UITextPosition *)positionWithinRange:(UITextRange *)range
                      atCharacterOffset:(NSInteger)offset {
  WLUnitFieldTextRange *r = (WLUnitFieldTextRange *)range;
  NSInteger newOffset = r.startOffset + offset;
  newOffset = MAX(r.startOffset, MIN(newOffset, r.endOffset));
  return [WLUnitFieldTextPosition positionWithOffset:newOffset];
}

- (NSInteger)characterOffsetOfPosition:(UITextPosition *)position
                           withinRange:(UITextRange *)range {
  WLUnitFieldTextPosition *pos = (WLUnitFieldTextPosition *)position;
  WLUnitFieldTextRange *r = (WLUnitFieldTextRange *)range;
  return pos.offset - r.startOffset;
}

- (BOOL)hasText {
  return _characterArray != nil && _characterArray.count > 0;
}

- (void)insertText:(NSString *)text {
  // 如果是从验证码自动填充来的，直接设置整个文本
  if (text.length >= _inputUnitCount &&
      [text rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]]
              .location != NSNotFound) {
    NSString *code = [text substringToIndex:MIN(text.length, _inputUnitCount)];
    self.text = code;
    [self sendActionsForControlEvents:UIControlEventEditingChanged];
    [self scheduleRedraw];
    return;
  }

  if ([text isEqualToString:@"\n"]) {
    [self resignFirstResponder];
    return;
  }

  if ([text isEqualToString:@" "]) {
    return;
  }

  // 输入验证（根据 allowedCharacterSet 验证）
  if (_allowedCharacterSet && ![self isValidInput:text]) {
    [self showInputError];
    return;
  }

  if (_characterArray.count >= _inputUnitCount) {
    if (_autoResignFirstResponderWhenInputFinished == YES) {
      [self resignFirstResponder];
    }
    return;
  }

  if ([self.delegate respondsToSelector:@selector
                     (unitField:
                         shouldChangeCharactersInRange:replacementString:)]) {
    if ([self.delegate unitField:self
            shouldChangeCharactersInRange:NSMakeRange(self.text.length,
                                                      text.length)
                        replacementString:text] == NO) {
      return;
    }
  }

  NSRange range;
  for (int i = 0; i < text.length; i += range.length) {
    range = [text rangeOfComposedCharacterSequenceAtIndex:i];
    [_characterArray addObject:[text substringWithRange:range]];
  }

  if (_characterArray.count >= _inputUnitCount) {
    [_characterArray removeObjectsInRange:NSMakeRange(_inputUnitCount,
                                                      _characterArray.count -
                                                          _inputUnitCount)];
    if (_autoResignFirstResponderWhenInputFinished == YES) {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self resignFirstResponder];
      }];
    }
  }

  [self sendActionsForControlEvents:UIControlEventEditingChanged];

  [self scheduleRedraw];
}

- (void)deleteBackward {
  if ([self hasText] == NO)
    return;

  [_characterArray removeLastObject];
  [self sendActionsForControlEvents:UIControlEventEditingChanged];

  [self scheduleRedraw];
}

@end
