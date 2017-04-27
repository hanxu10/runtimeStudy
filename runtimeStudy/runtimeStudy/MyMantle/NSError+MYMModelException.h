//
//  NSError+MYMModelException.h
//  rumtime
//
//  Created by hanxu on 2017/4/1.
//  Copyright © 2017年 hanxu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSError (MYMModelException)
/// 为更新MTLModel期间发生的异常创建新错误。
/// exception - 更新模型时抛出的异常。 这个参数不能是nil。
/// 返回一个错误，其中包含异常的本地化描述和失败原因。
+ (instancetype)mym_modelErrorWithException:(NSException *)exception;

@end
