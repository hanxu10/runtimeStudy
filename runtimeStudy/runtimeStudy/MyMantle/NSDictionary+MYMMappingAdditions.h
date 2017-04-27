//
//  NSDictionary+MYMMappingAdditions.h
//  rumtime
//
//  Created by hanxu on 2017/4/1.
//  Copyright © 2017年 hanxu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (MYMMappingAdditions)

///创建序列化的身份映射。
/// class - MTLModel的子类。
///返回将给定类的所有属性映射到自己的字典。
+ (NSDictionary *)mym_identityPropertyMapWithModel:(Class)modelClass;
@end
