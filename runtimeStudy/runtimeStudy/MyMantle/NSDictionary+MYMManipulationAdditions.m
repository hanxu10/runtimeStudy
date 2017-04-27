//
//  NSDictionary+MYMManipulationAdditions.m
//  rumtime
//
//  Created by hanxu on 2017/4/1.
//  Copyright © 2017年 hanxu. All rights reserved.
//

#import "NSDictionary+MYMManipulationAdditions.h"

@implementation NSDictionary (MYMManipulationAdditions)
- (NSDictionary *)mym_dictionaryByAddingEntriesFromDictionary:(NSDictionary *)dictionary {
    NSMutableDictionary *result = [self mutableCopy];
    [result addEntriesFromDictionary:dictionary];
    return result;
}

- (NSDictionary *)mym_dictionaryByRemovingValuesForKeys:(NSArray *)keys {
    NSMutableDictionary *result = [self mutableCopy];
    [result removeObjectsForKeys:keys];
    return result;
}
@end
