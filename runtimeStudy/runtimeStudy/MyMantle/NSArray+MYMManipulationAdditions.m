//
//  NSArray+MYMManipulationAdditions.m
//  rumtime
//
//  Created by hanxu on 2017/4/1.
//  Copyright © 2017年 hanxu. All rights reserved.
//

#import "NSArray+MYMManipulationAdditions.h"

@implementation NSArray (MYMManipulationAdditions)


- (NSArray *)mym_arrayByRemovingObject:(id)object {
    NSMutableArray *result = [self mutableCopy];
    [result removeObject:object];
    return result;
}

- (instancetype)mym_arrayByRemovingFirstObject {
    if (self.count == 0) return self;
    
    return [self subarrayWithRange:NSMakeRange(1, self.count - 1)];
}

- (instancetype)mym_arrayByRemovingLastObject {
    if (self.count == 0) return self;
    
    return [self subarrayWithRange:NSMakeRange(0, self.count - 1)];
}


@end
