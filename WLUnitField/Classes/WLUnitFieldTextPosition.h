//
//  WLUnitFieldTextPosition.h
//  WLUnitField
//
//  Created by 张尉 on 2019/4/3.
//  Copyright © 2019 wayne. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WLUnitFieldTextPosition : UITextPosition <NSCopying>

@property (nonatomic, readonly) NSInteger offset;

+ (instancetype)positionWithOffset:(NSInteger)offset;

@end

NS_ASSUME_NONNULL_END
