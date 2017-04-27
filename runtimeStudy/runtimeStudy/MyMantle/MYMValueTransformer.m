//
//  MYMValueTransformer.m
//  rumtime
//
//  Created by hanxu on 2017/4/1.
//  Copyright © 2017年 hanxu. All rights reserved.
//

#import "MYMValueTransformer.h"

//任何MTLValueTransformer支持反向转换。 有必要因为+ allowReverseTransformation是个类方法。
@interface MYMReversibleValueTransformer : MYMValueTransformer

@end






@interface MYMValueTransformer ()
@property (nonatomic, strong, readonly) MYMValueTransformerBlock forwardBlock;
@property (nonatomic, strong, readonly) MYMValueTransformerBlock reverseBlock;
@end
@implementation MYMValueTransformer
+ (instancetype)transformerUsingForwardBlock:(MYMValueTransformerBlock)transformation {
    return [[self alloc] initWithForwardBlock:transformation reverseBlock:nil];
}

+ (instancetype)transformerUsingReversibleBlock:(MYMValueTransformerBlock)transformation {
    return [[self alloc] initWithForwardBlock:transformation reverseBlock:transformation];
}

+ (instancetype)transformerUsingForwardBlock:(MYMValueTransformerBlock)forwardTransformation reverseBlock:(MYMValueTransformerBlock)reverseTransformation {
    return [[self alloc] initWithForwardBlock:forwardTransformation reverseBlock:reverseTransformation];
}

- (id)initWithForwardBlock:(MYMValueTransformerBlock)forwardBlock reverseBlock:(MYMValueTransformerBlock)reverseBlock {
    NSParameterAssert(forwardBlock != nil);
    
    self = [super init];
    if (self == nil) return nil;
    
    _forwardBlock = [forwardBlock copy];
    _reverseBlock = [reverseBlock copy];
    
    return self;
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

+ (Class)transformedValueClass {
    return [NSObject class];
}

- (id)transformedValue:(id)value {
    NSError *error = nil;
    BOOL success = YES;
    return self.forwardBlock(value, &success, &error);
}

- (id)transformedValue:(id)value success:(BOOL *)outerSuccess error:(NSError *__autoreleasing *)outerError {
    NSError *error = nil;
    BOOL success = YES;
    
    id transformedValue = self.forwardBlock(value, &success, &error);
    
    if (outerError != NULL) {
        *outerError = error;
    }
    if (outerSuccess != NULL) {
        *outerSuccess = success;
    }
    return transformedValue;
    
}

@end





@implementation MYMReversibleValueTransformer
- (id)initWithForwardBlock:(MYMValueTransformerBlock)forwardBlock reverseBlock:(MYMValueTransformerBlock)reverseBlock {
    NSParameterAssert(reverseBlock != nil);
    return [super initWithForwardBlock:forwardBlock reverseBlock:reverseBlock];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)reverseTransformedValue:(id)value {
    NSError *error = nil;
    BOOL success = YES;
    
    return self.reverseBlock(value, &success, &error);

}

- (id)reverseTransformedValue:(id)value success:(BOOL *)outerSuccess error:(NSError **)outerError {
    NSError *error = nil;
    BOOL success = YES;
    
    id transformedValue = self.reverseBlock(value, &success, &error);
    
    if (outerSuccess != NULL) *outerSuccess = success;
    if (outerError != NULL) *outerError = error;
    
    return transformedValue;
}



@end




