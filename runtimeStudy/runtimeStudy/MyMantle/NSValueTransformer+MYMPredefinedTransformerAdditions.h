//
//  NSValueTransformer+MYMPredefinedTransformerAdditions.h
//  rumtime
//
//  Created by hanxu on 2017/4/3.
//  Copyright © 2017年 hanxu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MYMTransformerErrorHandling.h"

// string <----> url 的transformer
extern NSString * const MYMURLValueTransformerName;

extern NSString * const MYMBooleanValueTransformerName;


@interface NSValueTransformer (MYMPredefinedTransformerAdditions)

//构造一个transformer，用于把数组中的每个元素进行转换
+ (NSValueTransformer<MYMTransformerErrorHandling> *)mym_arrayMappingTransformerWithTransformer:(NSValueTransformer *)transformer;


+ (NSValueTransformer<MYMTransformerErrorHandling> *)mym_valueMappingTransformerWithDictionary:(NSDictionary *)dictionary defaultValue:(id)defaultValue reverseDefaultValue:(id)reverseDefaultValue;
+ (NSValueTransformer<MYMTransformerErrorHandling> *)mym_valueMappingTransformerWithDictionary:(NSDictionary *)dictionary;

+ (NSValueTransformer<MYMTransformerErrorHandling> *)mym_dateTransformerWithDateFormat:(NSString *)dateFormat calendar:(NSCalendar *)calendar locale:(NSLocale *)locale timeZone:(NSTimeZone *)timeZone defaultDate:(NSDate *)defaultDate;

+ (NSValueTransformer<MYMTransformerErrorHandling> *)mym_dateTransformerWithDateFormat:(NSString *)dateFormat locale:(NSLocale *)locale;

+ (NSValueTransformer<MYMTransformerErrorHandling> *)mym_numberTransformerWithNumberStyle:(NSNumberFormatterStyle)numberStyle locale:(NSLocale *)locale;

+ (NSValueTransformer<MYMTransformerErrorHandling> *)mym_transformerWithFormatter:(NSFormatter *)formatter forObjectClass:(Class)objectClass;

+ (NSValueTransformer<MYMTransformerErrorHandling> *)mym_validatingTransformerForClass:(Class)modelClass;

@end











