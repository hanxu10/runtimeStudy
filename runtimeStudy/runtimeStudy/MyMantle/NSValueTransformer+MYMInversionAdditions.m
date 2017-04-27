//
//  NSValueTransformer+MYMInversionAdditions.m
//  rumtime
//
//  Created by hanxu on 2017/4/1.
//  Copyright © 2017年 hanxu. All rights reserved.
//

#import "NSValueTransformer+MYMInversionAdditions.h"
#import "MYMTransformerErrorHandling.h"
#import "MYMValueTransformer.h"

@implementation NSValueTransformer (MYMInversionAdditions)
- (NSValueTransformer *)mym_invertedTrasnsformer {
    NSParameterAssert(self.class.allowsReverseTransformation);
    
    if ([self conformsToProtocol:@protocol(MYMTransformerErrorHandling)]) {
        NSParameterAssert([self respondsToSelector:@selector(reverseTransformedValue:success:error:)]);
        
        id<MYMTransformerErrorHandling> errorHandlingSelf = (id)self;
        
        return [MYMValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
            return [errorHandlingSelf reverseTransformedValue:value success:success error:error];
        } reverseBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
            return [errorHandlingSelf transformedValue:value success:success error:error];
        }];
    } else {
        return [MYMValueTransformer transformerUsingForwardBlock:^(id value, BOOL *success, NSError **error) {
            return [self reverseTransformedValue:value];
        } reverseBlock:^(id value, BOOL *success, NSError **error) {
            return [self transformedValue:value];
        }];
    }
}
@end
