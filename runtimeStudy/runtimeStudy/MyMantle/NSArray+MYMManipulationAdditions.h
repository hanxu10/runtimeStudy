//
//  NSArray+MYMManipulationAdditions.h
//  rumtime
//
//  Created by hanxu on 2017/4/1.
//  Copyright © 2017年 hanxu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (MYMManipulationAdditions)

- (NSArray *)mym_arrayByRemovingObject:(id)object;

- (NSArray *)mym_arrayByRemovingFirstObject;

- (NSArray *)mym_arrayByRemovingLastObject;

@end
