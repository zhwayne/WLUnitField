//
//  WLUnitFieldTextRange.m
//  WLUnitField
//
//  Created by 张尉 on 2019/4/3.
//  Copyright © 2019 wayne. All rights reserved.
//

#import "WLUnitFieldTextRange.h"

@implementation WLUnitFieldTextRange
@dynamic range;
@synthesize start = _start, end = _end;


+ (instancetype)rangeWithRange:(NSRange)range {
    if (range.location == NSNotFound)
        return nil;
    
    WLUnitFieldTextPosition *start = [WLUnitFieldTextPosition positionWithOffset:range.location];
    WLUnitFieldTextPosition *end = [WLUnitFieldTextPosition positionWithOffset:range.location + range.length];
    return [self rangeWithStart:start end:end];
}

+ (instancetype)rangeWithStart:(WLUnitFieldTextPosition *)start end:(WLUnitFieldTextPosition *)end {
    if (!start || !end) return nil;
    assert(start.offset <= end.offset);
    WLUnitFieldTextRange *range = [[self alloc] init];
    range->_start = start;
    range->_end = end;
    return range;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    return [WLUnitFieldTextRange rangeWithStart:_start end:_end];
}

- (NSRange)range {
    return NSMakeRange(_start.offset, _end.offset - _start.offset);
}

@end
