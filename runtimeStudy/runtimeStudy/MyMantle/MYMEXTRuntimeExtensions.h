//
//  MYMEXTRuntimeExtensions.h
//  rumtime
//
//  Created by hanxu on 2017/3/10.
//  Copyright © 2017年 hanxu. All rights reserved.
//

#import <objc/runtime.h>

//描述一个property的内存管理策略
typedef enum {
    mym_propertyMemoryManagementPolicyAssign = 0,
    mym_propertyMemoryManagementPolicyRetain,
    mym_propertyMemoryManagementPolicyCopy
}mym_propertyMemoryManagementPolicy;

//描述一个property的attributes和type信息
typedef struct {
    //是否是readonly
    BOOL readonly;
    
    //是否是nonatomic
    BOOL nonatomic;
    
    //是否是weak
    BOOL weak;
    
    //该属性是否有资格进行垃圾回收。
    BOOL canBeCollected;
    
    //该属性是否用@dynnamic定义
    BOOL dynamic;
    
    //该property的内存管理策略。如果它的readnoly是yes，这个值就是mym_propertyMemoryManagementPolicyAssign
    mym_propertyMemoryManagementPolicy memoryManagementPolicy;
    
    //该property的gettter的selector。它能够反应自定义的getter = 某某某
    SEL getter;
    
    
    //该property的setter的selector。它能够反应自定义的setter = 某某某。
    //注意：如果readonly为YES，这个值将表示如果属性是可写的，setter将是什么。
    SEL setter;
    
    
    //此属性的支持实例变量，如果未使用@synthesize则为NULL，因此不存在实例变量。
    //如果属性动态实现，这也是这种情况。
    const char *ivar;
    
    //如果这个属性被定义为一个特定类的实例，这将是代表它的类对象。
    //如果属性被定义为类型id，如果属性不是对象类型，或者如果在运行时找不到类，那么这将是nil。
    Class objectClass;
    
    
    //此属性的值的类型编码。 这是类型，和由@encode（）指令返回的一样。
    //@encode(NSArray)获取代表这个类型的编码C字符串
    char type[];
    
} mym_propertyAttributes;

//返回一个结构体指针，包含一个property的信息。
//必须释放这个指针。如果获取信息出错，则返回NULL。
mym_propertyAttributes *mym_copyPropertyAttributes(objc_property_t property);











