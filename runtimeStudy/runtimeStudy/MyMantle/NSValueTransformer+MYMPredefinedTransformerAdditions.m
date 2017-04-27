//
//  NSValueTransformer+MYMPredefinedTransformerAdditions.m
//  rumtime
//
//  Created by hanxu on 2017/4/3.
//  Copyright © 2017年 hanxu. All rights reserved.
//

#import "NSValueTransformer+MYMPredefinedTransformerAdditions.h"
#import "MYMValueTransformer.h"
#import "MYMTransformerErrorHandling.h"

NSString * const MYMURLValueTransformerName = @"MYMURLValueTransformerName";
NSString * const MYMBooleanValueTransformerName = @"MYMBooleanValueTransformerName";

@implementation NSValueTransformer (MYMPredefinedTransformerAdditions)

+ (void)load {
    @autoreleasepool {
        MYMValueTransformer *URLValueTransformer = [MYMValueTransformer transformerUsingForwardBlock:^id(NSString *str, BOOL *success, NSError *__autoreleasing *error) {
            
            if (str == nil) {
                return nil;
            }
            
            if (![str isKindOfClass:NSString.class]) {
                if (error != NULL) {
                    NSDictionary *userInfo = @{
                                               NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert string to URL", @""),
                                               NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected an NSString, got: %@.", @""), str],
                                               MYMTransformerErrorHandlingInputValueErrorKey : str
                                               };
                    
                    *error = [NSError errorWithDomain:MYMTransformerErrorHandlingErrorDomain code:MYMTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
                }
                *success = NO;
                return nil;
            }
            
            NSURL *result = [NSURL URLWithString:str];
            if (result == nil) {
                if (error != NULL) {
                    NSDictionary *userInfo = @{
                                               NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert string to URL", @""),
                                               NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Input URL string %@ was malformed", @""), str],
                                               MYMTransformerErrorHandlingInputValueErrorKey : str
                                               };
                    
                    *error = [NSError errorWithDomain:MYMTransformerErrorHandlingErrorDomain code:MYMTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
                }
                *success = NO;
                return nil;
            }
            
            return result;
            
        } reverseBlock:^id(NSURL *URL, BOOL *success, NSError *__autoreleasing *error) {
            if (URL == nil) return nil;
            
            if (![URL isKindOfClass:NSURL.class]) {
                if (error != NULL) {
                    NSDictionary *userInfo = @{
                                               NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert URL to string", @""),
                                               NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected an NSURL, got: %@.", @""), URL],
                                               MYMTransformerErrorHandlingInputValueErrorKey : URL
                                               };
                    
                    *error = [NSError errorWithDomain:MYMTransformerErrorHandlingErrorDomain code:MYMTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
                }
                *success = NO;
                return nil;
            }
            return URL.absoluteString;
        }];
        
        [NSValueTransformer setValueTransformer:URLValueTransformer forName:MYMURLValueTransformerName];
        
        
        MYMValueTransformer *booleanValueTransformer = [MYMValueTransformer transformerUsingReversibleBlock:^id(NSNumber *boolean, BOOL *success, NSError *__autoreleasing *error) {
            if (boolean == nil) {
                return nil;
            }
            
            if (![boolean isKindOfClass:NSNumber.class]) {
                if (error != NULL) {
                    NSDictionary *userInfo = @{
                                               NSLocalizedDescriptionKey : NSLocalizedString(@"Could not convert number to boolean-backed number or vice-versa", @:""),
                                               NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:NSLocalizedString(@"Expected an NSNumber, got: %@.", @""),boolean],
                                               MYMTransformerErrorHandlingInputValueErrorKey : boolean
                                               };
                    *error = [NSError errorWithDomain:MYMTransformerErrorHandlingErrorDomain code:MYMTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
                    *success = NO;
                    return nil;
                }
            }
            return (NSNumber *)(boolean.boolValue ? kCFBooleanTrue : kCFBooleanFalse);
        }];
        
        [NSValueTransformer setValueTransformer:booleanValueTransformer forName:MYMBooleanValueTransformerName];
        
    }
}



+ (NSValueTransformer<MYMTransformerErrorHandling> *)mym_arrayMappingTransformerWithTransformer:(NSValueTransformer *)transformer {
    
    NSParameterAssert(transformer != nil);
    
    id (^forwardBlock)(NSArray *values, BOOL *success, NSError **error) = ^ id (NSArray *values, BOOL *success, NSError **error) {
        if (values == nil) {
            return nil;
        }
        
        if (![values isKindOfClass:NSArray.class]) {
            if (error != NULL) {
                NSDictionary *userInfo = @{
                                           NSLocalizedDescriptionKey: NSLocalizedString(@"Could not transform non-array type", @""),
                                           NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected an NSArray, got: %@.", @""), values],
                                           MYMTransformerErrorHandlingInputValueErrorKey: values
                                           };
                
                *error = [NSError errorWithDomain:MYMTransformerErrorHandlingErrorDomain code:MYMTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
            }
            *success = NO;
            return nil;
        }
        
        NSMutableArray *transformedValues = [NSMutableArray arrayWithCapacity:values.count];
        NSInteger index = -1;
        for (id value in values) {
            index ++;
            if (value == NSNull.null) {
                [transformedValues addObject:NSNull.null];
                continue;
            }
            
            id transformedValue = nil;
            if ([transformer conformsToProtocol:@protocol(MYMTransformerErrorHandling)]) {
                NSError *underlyingError = nil;
                transformedValue = [(id<MYMTransformerErrorHandling>)transformedValue transformedValue:value success:success error:&underlyingError];
                
                if (*success == NO) {
                    if (error != NULL) {
                        NSDictionary *userInfo = @{
                                                   NSLocalizedDescriptionKey: NSLocalizedString(@"Could not transform array", @""),
                                                   NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Could not transform value at index %d", @""), index],
                                                   NSUnderlyingErrorKey: underlyingError,
                                                   MYMTransformerErrorHandlingInputValueErrorKey: values
                                                   };
                        
                        *error = [NSError errorWithDomain:MYMTransformerErrorHandlingErrorDomain code:MYMTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
                    }
                    return nil;
                }
            } else {
                transformedValue = [transformer transformedValue:value];
            }
            if (transformedValue == nil) {
                continue;
            }
            [transformedValues addObject:transformedValue];
        }
        return transformedValues;
    };
    
    id (^reverseBlock)(NSArray *values, BOOL *success, NSError **error) = nil;
    if (transformer.class.allowsReverseTransformation) {
        reverseBlock = ^ id (NSArray *values, BOOL *success, NSError **error) {
            if (values == nil) return nil;
            
            if (![values isKindOfClass:NSArray.class]) {
                if (error != NULL) {
                    NSDictionary *userInfo = @{
                                               NSLocalizedDescriptionKey: NSLocalizedString(@"Could not transform non-array type", @""),
                                               NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected an NSArray, got: %@.", @""), values],
                                               MYMTransformerErrorHandlingInputValueErrorKey: values
                                               };
                    
                    *error = [NSError errorWithDomain:MYMTransformerErrorHandlingErrorDomain code:MYMTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
                }
                *success = NO;
                return nil;
            }
            
            NSMutableArray *transformedValues = [NSMutableArray arrayWithCapacity:values.count];
            NSInteger index = -1;
            for (id value in values) {
                index++;
                if (value == NSNull.null) {
                    [transformedValues addObject:NSNull.null];
                    
                    continue;
                }
                
                id transformedValue = nil;
                if ([transformer respondsToSelector:@selector(reverseTransformedValue:success:error:)]) {
                    NSError *underlyingError = nil;
                    transformedValue = [(id<MYMTransformerErrorHandling>)transformer reverseTransformedValue:value success:success error:&underlyingError];
                    
                    if (*success == NO) {
                        if (error != NULL) {
                            NSDictionary *userInfo = @{
                                                       NSLocalizedDescriptionKey: NSLocalizedString(@"Could not transform array", @""),
                                                       NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Could not transform value at index %d", @""), index],
                                                       NSUnderlyingErrorKey: underlyingError,
                                                       MYMTransformerErrorHandlingInputValueErrorKey: values
                                                       };
                            
                            *error = [NSError errorWithDomain:MYMTransformerErrorHandlingErrorDomain code:MYMTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
                        }
                        return nil;
                    }
                } else {
                    transformedValue = [transformer reverseTransformedValue:value];
                }
                
                if (transformedValue == nil) continue;
                
                [transformedValues addObject:transformedValue];
            }
            
            return transformedValues;
        };
    }
    
    if (reverseBlock != nil) {
        return [MYMValueTransformer transformerUsingForwardBlock:forwardBlock reverseBlock:reverseBlock];
    } else {
        return [MYMValueTransformer transformerUsingForwardBlock:forwardBlock];
    }

}


+ (NSValueTransformer<MYMTransformerErrorHandling> *)mym_valueMappingTransformerWithDictionary:(NSDictionary *)dictionary defaultValue:(id)defaultValue reverseDefaultValue:(id)reverseDefaultValue {
    NSParameterAssert(dictionary != nil);
    NSParameterAssert(dictionary.count == [[NSSet setWithArray:dictionary.allValues] count]);
    
    return [MYMValueTransformer transformerUsingForwardBlock:^id(id <NSCopying> key, BOOL *success, NSError *__autoreleasing *error) {
        
        return dictionary[key ?: NSNull.null] ?: defaultValue;
        
    } reverseBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
        __block id result = nil;
        [dictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if ([value isEqual:obj]) {
                result = key;
                *stop = YES;
            }
        }];
        return result ?: reverseDefaultValue;
    }];
}


+ (NSValueTransformer<MYMTransformerErrorHandling> *)mym_valueMappingTransformerWithDictionary:(NSDictionary *)dictionary {
    return [self mym_valueMappingTransformerWithDictionary:dictionary defaultValue:nil reverseDefaultValue:nil];
}



+ (NSValueTransformer<MYMTransformerErrorHandling> *)mym_dateTransformerWithDateFormat:(NSString *)dateFormat calendar:(NSCalendar *)calendar locale:(NSLocale *)locale timeZone:(NSTimeZone *)timeZone defaultDate:(NSDate *)defaultDate {
    NSParameterAssert(dateFormat.length);
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = dateFormat;
    dateFormatter.calendar = calendar;
    dateFormatter.locale = locale;
    dateFormatter.timeZone = timeZone;
    dateFormatter.defaultDate = defaultDate;
    
    return [NSValueTransformer mym_transformerWithFormatter:dateFormatter forObjectClass:NSDate.class];
}


+ (NSValueTransformer<MYMTransformerErrorHandling> *)mym_transformerWithFormatter:(NSFormatter *)formatter forObjectClass:(Class)objectClass {
    NSParameterAssert(formatter != nil);
    NSParameterAssert(objectClass != nil);
    return [MYMValueTransformer transformerUsingForwardBlock:^id(NSString *str, BOOL *success, NSError *__autoreleasing *error) {
        if (str == nil) {
            return nil;
        }
        
        if (![str isKindOfClass:NSString.class]) {
            if (error != NULL) {
                NSDictionary *userInfo = @{
                                           NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"Could not convert string to %@", @""), objectClass],
                                           NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected an NSString as input, got: %@.", @""), str],
                                           MYMTransformerErrorHandlingInputValueErrorKey : str
                                           };
                
                *error = [NSError errorWithDomain:MYMTransformerErrorHandlingErrorDomain code:MYMTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
            }
            *success = NO;
            return nil;

        }
        
        id object = nil;
        NSString *errorDescription = nil;
        *success = [formatter getObjectValue:&object forString:str errorDescription:&errorDescription];
        
        if (errorDescription != nil) {
            if (error != NULL) {
                NSDictionary *userInfo = @{
                                           NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"Could not convert string to %@", @""), objectClass],
                                           NSLocalizedFailureReasonErrorKey: errorDescription,
                                           MYMTransformerErrorHandlingInputValueErrorKey : str
                                           };
                
                *error = [NSError errorWithDomain:MYMTransformerErrorHandlingErrorDomain code:MYMTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
            }
            *success = NO;
            return nil;
        }
        
        if (![object isKindOfClass:objectClass]) {
            if (error != NULL) {
                NSDictionary *userInfo = @{
                                           NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"Could not convert string to %@", @""), objectClass],
                                           NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected an %@ as output from the formatter, got: %@.", @""), objectClass, object],
                                           };
                
                *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFormattingError userInfo:userInfo];
            }
            *success = NO;
            return nil;
        }
        
        return object;
        
    } reverseBlock:^id(id object, BOOL *success, NSError *__autoreleasing *error) {
        
        if (![object isKindOfClass:objectClass]) {
            if (error != NULL) {
                NSDictionary *userInfo = @{
                                           NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"Could not convert %@ to string", @""), objectClass],
                                           NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected an %@ as input, got: %@.", @""), objectClass, object],
                                           MYMTransformerErrorHandlingInputValueErrorKey : object
                                           };
                
                *error = [NSError errorWithDomain:MYMTransformerErrorHandlingErrorDomain code:MYMTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
            }
            *success = NO;
            return nil;
            
        }
        NSString *string = [formatter stringForObjectValue:object];
        *success = (string != nil);
        return string;
        
    }];
}



+ (NSValueTransformer<MYMTransformerErrorHandling> *)mym_dateTransformerWithDateFormat:(NSString *)dateFormat locale:(NSLocale *)locale {
    return [self mym_dateTransformerWithDateFormat:dateFormat calendar:nil locale:locale timeZone:nil defaultDate:nil];
}


+ (NSValueTransformer<MYMTransformerErrorHandling> *)mym_numberTransformerWithNumberStyle:(NSNumberFormatterStyle)numberStyle locale:(NSLocale *)locale {
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.numberStyle = numberStyle;
    numberFormatter.locale = locale;
    
    return [self mym_transformerWithFormatter:numberFormatter forObjectClass:NSNumber.class];
}


+ (NSValueTransformer<MYMTransformerErrorHandling> *)mym_validatingTransformerForClass:(Class)modelClass {
    return [MYMValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
        if (value != nil && ![value isKindOfClass:modelClass]) {
            if (error != NULL) {
                NSDictionary *userInfo = @{
                                           NSLocalizedDescriptionKey: NSLocalizedString(@"Value did not match expected type", @""),
                                           NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected %1$@ to be of class %2$@ but got %3$@", @""), value, modelClass, [value class]],
                                           MYMTransformerErrorHandlingInputValueErrorKey : value
                                           };
                
                *error = [NSError errorWithDomain:MYMTransformerErrorHandlingErrorDomain code:MYMTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
            }
            *success = NO;
            return nil;
        }
        return value;
    }];
}




@end
