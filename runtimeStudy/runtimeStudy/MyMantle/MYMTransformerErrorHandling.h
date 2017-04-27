//
//  MYMTransformerErrorHandling.h
//  rumtime
//
//  Created by hanxu on 2017/4/1.
//  Copyright © 2017年 hanxu. All rights reserved.
//

#import <Foundation/Foundation.h>

/// The domain for errors originating from the MYMTransformerErrorHandling
/// protocol.
///
/// Transformers conforming to this protocol are expected to use this error
/// domain if the transformation fails.
extern NSString * const MYMTransformerErrorHandlingErrorDomain;

/// Used to indicate that the input value was illegal.
///
/// Transformers conforming to this protocol are expected to use this error code
/// if the transformation fails due to an invalid input value.
extern const NSInteger MYMTransformerErrorHandlingErrorInvalidInput;



/// Associated with the invalid input value.
///
/// Transformers conforming to this protocol are expected to associate this key
/// with the invalid input in the userInfo dictionary.
extern NSString * const MYMTransformerErrorHandlingInputValueErrorKey;



///该协议可以由NSValueTransformer子类实现，以传达转换过程中发生的错误。
@protocol MYMTransformerErrorHandling <NSObject>
@required

/// 转换一个值，返回转换过程中发生的任何错误。
///
/// value - 要转换的值。
/// success - 如果不是NULL，这将被设置为一个布尔值，指示转换是否成功。
/// error - 如果不为NULL，则可能会将其设置为在转换值期间发生的错误。
///返回可能为nil的转换结果。 客户应检查成功参数以决定如何继续执行结果。
- (id)transformedValue:(id)value success:(BOOL *)success error:(NSError **)error;

@optional


///反转换一个值，返回变换过程中发生的任何错误。
///遵从此协议的transformer如果支持反向转换，应当实现此方法。
///
/// value - 要转换的值。
/// success - 如果不是NULL，这将被设置为一个布尔值，指示转换是否成功。
/// error - 如果不为NULL，则可能会将其设置为在转换值期间发生的错误。
///
///返回可能为零的反向转换的结果。 客户应检查成功参数以决定如何继续执行结果。
- (id)reverseTransformedValue:(id)value success:(BOOL *)success error:(NSError **)error;

@end
