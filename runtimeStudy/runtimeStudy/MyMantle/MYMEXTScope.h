//
//  MYMEXTScope.h
//  rumtime
//
//  Created by hanxu on 2017/3/8.
//  Copyright © 2017年 hanxu. All rights reserved.
//

#import "metamacros.h"

typedef void (^mtl_cleanupBlock_t)();

//用__attribute__((cleanup(函数1))，unused)修饰一个变量，当这个变量作用域结束时，可以执行一个指定的方法。


// void stringCleanUp(__strong NSString **string) {
//   NSLog(@"%@", *string);
// }
// 在某个方法中：
// {
//     __strong NSString *string __attribute__((cleanup(stringCleanUp))) = @"sunnyxx";
// }// 当运行到这个作用域结束时，自动调用stringCleanUp

//这个变量可以是个block。
// void blockCleanupfunction(__strong mtl_cleanupBlock_t *t){
//     (*t)();
// }
//
// __strong mtl_cleanupBlock_t blocktemp __attribute__((cleanup(blockCleanupfunction),unused)) = ^{
//     NSLog(@"用完了");
// };








#define onExit \
    try {} \
    @finally {}\
    __strong mtl_cleanupBlock_t metamacro_concat(mtl_exitBlock_, __LINE__) __attribute__((cleanup(mtl_executeCleanupBlock),unused)) = ^





#define weakify(...) \
try {} @finally {} \
metamacro_foreach_cxt(mtl_weakify_,, __weak, __VA_ARGS__)



#define unsafeify(...) \
try {} @finally {} \
metamacro_foreach_cxt(mtl_weakify_,, __unsafe_unretained, __VA_ARGS__)



#define strongify(...) \
try {} @finally {} \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
metamacro_foreach(mtl_strongify_,, __VA_ARGS__) \
_Pragma("clang diagnostic pop")





#define mtl_weakify_(INDEX, CONTEXT, VAR) \
CONTEXT __typeof__(VAR) metamacro_concat(VAR, _weak_) = (VAR);

#define mtl_strongify_(INDEX, VAR) \
__strong __typeof__(VAR) VAR = metamacro_concat(VAR, _weak_);

void mtl_executeCleanupBlock (__strong mtl_cleanupBlock_t *block);










