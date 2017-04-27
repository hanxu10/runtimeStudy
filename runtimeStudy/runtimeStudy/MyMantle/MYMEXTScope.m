//
//  MYMEXTScope.m
//  rumtime
//
//  Created by hanxu on 2017/3/8.
//  Copyright © 2017年 hanxu. All rights reserved.
//

#import "MYMEXTScope.h"

void mtl_executeCleanupBlock (__strong mtl_cleanupBlock_t *block) {
    (*block)();
}
