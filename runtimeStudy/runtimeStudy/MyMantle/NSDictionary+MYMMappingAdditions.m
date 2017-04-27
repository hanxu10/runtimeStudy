//
//  NSDictionary+MYMMappingAdditions.m
//  rumtime
//
//  Created by hanxu on 2017/4/1.
//  Copyright © 2017年 hanxu. All rights reserved.
//

#import "NSDictionary+MYMMappingAdditions.h"
#import "MYMModel.h"

@implementation NSDictionary (MYMMappingAdditions)
+ (NSDictionary *)mym_identityPropertyMapWithModel:(Class)modelClass {
    NSParameterAssert([modelClass conformsToProtocol:@protocol(MYMModel)]);
    NSArray *propertyKeys = [modelClass propertyKeys].allObjects;
    return [NSDictionary dictionaryWithObjects:propertyKeys forKeys:propertyKeys];
}

@end
