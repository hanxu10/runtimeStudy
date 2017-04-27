//
//  MYMValueTransformer.h
//  rumtime
//
//  Created by hanxu on 2017/4/1.
//  Copyright © 2017年 hanxu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MYMTransformerErrorHandling.h"

///表示转换的块。
///
/// value - 要转换的值。
/// success - 块必须设置此参数以指示转换是否成功。
/// MTLValueTransformer将始终将*成功初始化为YES。
/// error - 如果不为NULL，则可能会将其设置为在转换值期间发生的错误。
///
///返回转换的结果，可能为nil。
typedef id(^MYMValueTransformerBlock)(id value, BOOL *success, NSError **error);



///支持基于block的值变换器。
@interface MYMValueTransformer : NSValueTransformer<MYMTransformerErrorHandling>


///返回使用给定block转换值的变换器。 不允许反向转换。
+ (instancetype)transformerUsingForwardBlock:(MYMValueTransformerBlock)transformation;

///返回使用给定block转换值的变换器，用于正向或反向转换。
+ (instancetype)transformerUsingReversibleBlock:(MYMValueTransformerBlock)transformation;

/// Returns a transformer which transforms values using the given blocks.
+ (instancetype)transformerUsingForwardBlock:(MYMValueTransformerBlock)forwardTransformation reverseBlock:(MYMValueTransformerBlock)reverseTransformation;


@end
