//
//  WLUnitFieldTextRange.m
//  WLUnitField
//
//  Created by 张尉 on 2019/4/3.
//  Copyright © 2019 wayne. All rights reserved.
//

#import "WLUnitFieldTextRange.h"

@implementation WLUnitFieldTextRange {
    WLUnitFieldTextPosition *_start;
    WLUnitFieldTextPosition *_end;
}

- (WLUnitFieldTextPosition *)start {
    return _start;
}

- (WLUnitFieldTextPosition *)end {
    return _end;
}

+ (instancetype)rangeWithRange:(NSRange)range {
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
    return [self.class rangeWithStart:_start end:_end];
}

- (NSRange)range {
    return NSMakeRange(_start.offset, _end.offset - _start.offset);
}

@end
