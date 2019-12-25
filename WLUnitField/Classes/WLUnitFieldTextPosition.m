//
//  WLUnitFieldTextPosition.m
//  WLUnitField
//
//  Created by 张尉 on 2019/4/3.
//  Copyright © 2019 wayne. All rights reserved.
//

#import "WLUnitFieldTextPosition.h"

@implementation WLUnitFieldTextPosition

+ (instancetype)positionWithOffset:(NSInteger)offset {
    WLUnitFieldTextPosition *position = [[self alloc] init];
    position->_offset = offset;
    return position;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    return [WLUnitFieldTextPosition positionWithOffset:self.offset];
}

@end
