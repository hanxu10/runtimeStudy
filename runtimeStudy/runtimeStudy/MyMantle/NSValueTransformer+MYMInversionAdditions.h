//
//  NSValueTransformer+MYMInversionAdditions.h
//  rumtime
//
//  Created by hanxu on 2017/4/1.
//  Copyright © 2017年 hanxu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSValueTransformer (MYMInversionAdditions)

///翻转接收器转换的方向，如-transformedValue：将变为-reverseTransformedValue：，反之亦然。
///接收机必须允许反向转换。
///返回一个反向的转换器。
- (NSValueTransformer *)mym_invertedTrasnsformer;
@end
