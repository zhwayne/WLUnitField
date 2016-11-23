//
//  YGColorDefinition.h
//  randomColor
//
//  Created by Yannick Heinrich on 21/05/15.
//  Copyright (c) 2015 yageek. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
typedef NS_ENUM(NSUInteger, YGColorLuminosity) {
    YGColorLuminosityDark,
    YGColorLuminosityBright,
    YGColorLuminosityLight,
    YGColorLuminosityRandom
};

typedef NS_ENUM(NSUInteger, YGColorHue) {
    YGColorHueRed,
    YGColorHueOrange,
    YGColorHueYellow,
    YGColorHueGreen,
    YGColorHueBlue,
    YGColorHuePurple,
    YGColorHuePink,
    YGColorHueMonochrome,
    YGColorHueRandom
};

#pragma mark - YGColorRange

@interface YGColorRange : NSObject

+ (instancetype) newWithMin:(CGFloat) min max:(CGFloat)max;
- (instancetype) initWithMin:(CGFloat) min max:(CGFloat)max;

@property(nonatomic)CGFloat min;
@property(nonatomic)CGFloat max;

@end


#pragma mark - YGColorDefinition

@interface YGColorDefinition : NSObject

- (id) initWithHueRange:(YGColorRange*) hueRange lowerBounds:(NSArray*) lowerBounds;


@property(nonatomic, strong) YGColorRange* hueRange;
@property(nonatomic, strong) YGColorRange* saturationRange;
@property(nonatomic, strong) YGColorRange* brightnessRange;
@property(nonatomic, copy) NSArray* lowerBounds;

+ (CGFloat) pickHueWithEnum:(YGColorHue) hue;
+ (CGFloat) pickSaturationWithHueValue:(CGFloat) hue luminosity:(YGColorLuminosity) luminosity monochrome:(BOOL) isMonochrome;
+ (CGFloat) pickBrightnessWitHueValue:(CGFloat) hue saturationValue:(CGFloat) saturation luminosity:(YGColorLuminosity) luminosity;
@end
