//
//  YGColorDefinition.m
//  randomColor
//
//  Created by Yannick Heinrich on 21/05/15.
//  Copyright (c) 2015 yageek. All rights reserved.
//

#import "YGColorDefinition.h"

#define YGRange(MinVal, MaxVal) [YGColorRange newWithMin:MinVal max:MaxVal]

@implementation YGColorRange

- (instancetype) initWithMin:(CGFloat) min max:(CGFloat)max
{
    if(self = [super init])
    {
        _max = max;
        _min = min;
    }
    return self;
}

+ (instancetype) newWithMin:(CGFloat) min max:(CGFloat)max
{
    return [[[self class] alloc] initWithMin:min max:max];
}

- (NSString*) description
{
    return [NSString stringWithFormat:@"<%p:%@> min:%f max:%f", self, NSStringFromClass([self class]), self.min, self.max];
}
@end


@implementation YGColorDefinition

- (id) initWithHueRange:(YGColorRange*) hueRange lowerBounds:(NSArray*) lowerBounds
{
    if(self = [super init])
    {
        
        YGColorRange * sMin = [lowerBounds firstObject];
        YGColorRange * sMax = [lowerBounds lastObject];
        
        _hueRange = hueRange;
        _lowerBounds = [lowerBounds copy];
        _saturationRange = [YGColorRange newWithMin:sMin.min max:sMax.min];
        _brightnessRange = [YGColorRange newWithMin:sMax.max max:sMin.max];
        
    }
    return self;
}

+ (NSMutableDictionary*) sharedColors
{
    static NSMutableDictionary * dict = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        dict = [[NSMutableDictionary alloc] init];
    });
    return dict;
}

+ (void) load
{
    

    
    //Populate the dictionary
    [self loadColorBounds];
}

+ (void) defineColorWithName:(NSString*) name hueRange:(YGColorRange*) hueRange lowerBounds:(NSArray*) lowerBounds
{
    YGColorDefinition *definition = [[YGColorDefinition alloc] initWithHueRange:hueRange lowerBounds:lowerBounds];
    
    NSMutableDictionary* colorDict = [self sharedColors];
    colorDict[name] = definition;
}


+ (void) loadColorBounds
{
    [self defineColorWithName:@"monochrome"
                     hueRange:nil
                  lowerBounds:@[YGRange(0,0),YGRange(100,0)]];
    
    [self defineColorWithName:@"red"
                     hueRange:YGRange(-26,18)
                  lowerBounds:@[YGRange(20,100),YGRange(30,92),YGRange(40,89),YGRange(50,85),YGRange(60,78),YGRange(70,70),YGRange(80,60),YGRange(90,55),YGRange(100,50)]];
    
    
    [self defineColorWithName:@"orange"
                     hueRange:YGRange(19,46)
                  lowerBounds:@[YGRange(20,100),YGRange(30,93),YGRange(40,88),YGRange(50,86),YGRange(60,85),YGRange(70,70),YGRange(100,70)]];
    
    
    [self defineColorWithName:@"yellow"
                     hueRange:YGRange(47, 62)
                  lowerBounds:@[YGRange(25,100),YGRange(40,94),YGRange(50,89),YGRange(60,86),YGRange(70,84),YGRange(80,82),YGRange(90,80),YGRange(100,75)]];
    
    [self defineColorWithName:@"green"
                     hueRange:YGRange(63, 178)
                  lowerBounds:@[YGRange(30,100),YGRange(40,90),YGRange(50,85),YGRange(60,81),YGRange(70,74),YGRange(80,64),YGRange(90,50),YGRange(100,40)]];
    
    [self defineColorWithName:@"blue"
                     hueRange:YGRange(179, 257)
                  lowerBounds:@[YGRange(20,100),YGRange(30,86),YGRange(40,80),YGRange(50,74),YGRange(60,60),YGRange(70,52),YGRange(80,44),YGRange(90,39), YGRange(100, 35)]];
    
    [self defineColorWithName:@"purple"
                     hueRange:YGRange(258, 282)
                  lowerBounds:@[YGRange(20,100),YGRange(30,87),YGRange(40,79),YGRange(50,70),YGRange(60,65),YGRange(70,59),YGRange(80,52),YGRange(90,45), YGRange(100, 42)]];
    
    [self defineColorWithName:@"pink"
                     hueRange:YGRange(283, 334)
                  lowerBounds:@[YGRange(20,100),YGRange(30,90),YGRange(40,86),YGRange(60,84),YGRange(80,80),YGRange(90,75),YGRange(100,73)]];
    
}

+ (YGColorRange*) hueRange:(id) colorInput
{
    if([colorInput isKindOfClass:[NSNumber class]])
    {
        CGFloat number = [colorInput floatValue];
        return (number < 360 && number > 0) ? YGRange(number, number) : YGRange(0, 360);
    }
    else if([colorInput isKindOfClass:[NSString class]])
    {
        YGColorDefinition * color = [self sharedColors][colorInput];
        return color.hueRange ?: YGRange(0, 360);
    }
    
    
    return YGRange(0, 360);
    
}

+ (CGFloat) pickHueWithEnum:(YGColorHue) hue
{
    return [self pickHue:[self colorNameFromEnum:hue]];
}
+ (CGFloat) pickHue:(id) colorInput
{
    YGColorRange * range = [[self class] hueRange:colorInput];
    CGFloat hue = [self randomWithin:range];
    if (hue < 0) {hue = 360 + hue;}
    return hue;
}

#pragma mark - Random

+ (CGFloat) randomWithin:(YGColorRange*) range
{
    return arc4random_uniform(range.max - range.min) + range.min;
}


+ (YGColorRange*) saturationRange:(CGFloat) hue
{
    return [[self colorInfo:hue] saturationRange];
}

+ (CGFloat) pickSaturationWithHueValue:(CGFloat) hue luminosity:(YGColorLuminosity) luminosity monochrome:(BOOL) isMonochrome
{
    
    if(isMonochrome)
        return 0;
    
    YGColorRange *saturationRange = [self saturationRange:hue];
    
    CGFloat sMin = saturationRange.min;
    CGFloat sMax = saturationRange.max;
    
    switch (luminosity) {
        case YGColorLuminosityBright:
            sMin  = 55;
            break;
        case YGColorLuminosityDark:
            sMin = sMax -10;
            break;
        case YGColorLuminosityLight:
            sMax = 55;
            break;
        case YGColorLuminosityRandom:
            return [self randomWithin:YGRange(0, 100)];
            break;
    }
    
    return [self randomWithin:YGRange(sMin, sMax)];
}

+ (CGFloat) minimumBrightnessWithHue:(CGFloat) hue saturation:(CGFloat) saturation
{
    NSArray * lowerBounds = [self colorInfo:hue].lowerBounds;
    
    for(NSUInteger idx = 0; idx < lowerBounds.count -1 ; ++idx)
    {
        YGColorRange * range = lowerBounds[idx];
        CGFloat s1 = range.min;
        CGFloat v1 = range.max;
        
        CGFloat s2 = [lowerBounds[idx+1] min];
        CGFloat v2 = [lowerBounds[idx+1] max];
        
        if(saturation >= s1 && saturation <= s2)
        {
            CGFloat m = (v2 - v1)/(s2 - s1);
            CGFloat  b = v1 - m*s1;
            return (m*saturation + b);
        }
        
    }
    return 0;
}


+ (CGFloat) pickBrightnessWitHueValue:(CGFloat) hue saturationValue:(CGFloat) saturation luminosity:(YGColorLuminosity) luminosity
{
    CGFloat bMin = [self minimumBrightnessWithHue:hue saturation:saturation];
    CGFloat bMax = 100;
    
    switch (luminosity) {
        case YGColorLuminosityDark:
            bMax = bMin + 20;
            break;
        case YGColorLuminosityLight:
            bMin = (bMax + bMin)/2.0f;
            break;
        case YGColorLuminosityRandom:
            bMin = 0;
            bMax = 100;
            break;
        default:
            break;
    }
    return [self randomWithin:YGRange(bMin, bMax)];
}


+ (YGColorDefinition*) colorInfo:(CGFloat) hue
{
    if (hue >= 334 && hue <= 360) {
        hue-= 360;
    }
    
    for(YGColorDefinition* color in [[self sharedColors] allValues])
    {
        if(color.hueRange &&
           hue >= color.hueRange.min &&
           hue <= color.hueRange.max)
            return color;
    }
    
    return nil;
}

+ (NSString*) colorNameFromEnum:(YGColorHue) hueEnum
{
    switch (hueEnum)
    {
        case YGColorHueRed : return @"red";
        case YGColorHueOrange: return @"orange";
        case YGColorHueYellow: return @"yellow";
        case YGColorHueGreen: return @"green";
        case YGColorHueBlue: return @"blue";
        case YGColorHuePurple: return @"purple";
        case YGColorHuePink: return @"pink";
        case YGColorHueMonochrome: return @"monochrome";
        case YGColorHueRandom: return nil;
            
    }
}

@end
