//
//  XXClassInfo.h
//  runtimeStudy
//
//  Created by hanxu on 2017/4/28.
//  Copyright © 2017年 hanxu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
NS_ASSUME_NONNULL_BEGIN
//https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
//类型编码
//为了协助运行时系统，编译器将每个方法的返回值和参数类型进行编码,得到一个特定的字符串，并将该字符串与方法选择器相关联。
//它使用的编码方案在其他上环境中也很有用，因此通过@encode()这个编译器指令进行了公开。
//当给定类型说明时，@encode()返回一个编码该类型的字符串。该类型可以是基本类型，例如int，指针，a tagged structure or union，或类名称 - 实际上可以用作C语言 sizeof() 运算符的任何参数。

//下表列出了类型代码。
//请注意，它们中的许多与您为了归档或分发目的而编码对象时使用的代码重叠。
//但是，这里列出来的一些代码在编写coder时无法使用，还有些代码是你在编写不是由@encode()生成的coder时可能需要使用的代码。 （有关编码对象以进行归档或分发的详细信息，请参阅Foundation Framework参考中的NSCoder类规范。）


//Objective-C type encodings

//char                      --->c
//int                       --->i
//short                     --->s
//long                      --->q
//long long                 --->q
//unsigned char             --->C
//unsigned int              --->I
//unsigned short            --->S
//unsigned long             --->Q
//unsigned long long        --->Q
//float                     --->f
//double                    --->d

//bool                      --->B
//BOOL                      --->B


//void                      --->v
//char*                     --->*
//id                        --->@
//对象                       --->@ (例如: @encode(NSString *) ==> @)
//类对象(Class)              --->(   例如:   @encode(PersonModel)==>{PersonModel=#}
//                                         @encode(NSArray)==>{NSArray=#}      )
//SEL                       --->:


//float[5]                  --->[5f]
//int[3]                    --->[3i]
//int[]                     --->^i
//int*                      --->^i
//char*                     --->*   与int* ,float*不同
//char[]                    --->^c

//block                     --->@?


//typedef struct example {
//    id   anObject;
//    char *aString;        ---> {example=@*i}
//    int  anInt;
//} Example;


//请注意，虽然@encode()指令不返回它们，但运行时系统使用下列的附加编码,用于在协议中声明方法时进行类型限定。
//const                 --->r
//in                    --->n
//inout                 --->N
//out                   --->o
//bycopy                --->O
//byref                 --->R
//oneway                --->v


//in：参数只是一个输入参数，不再被引用
//out： argument只是一个输出参数，用于通过引用返回一个值
//inout：参数既是输入参数也是输出参数
//const：（指针）参数是常量
//bycopy：不使用proxy/ NSDistantObject，而是传递或返回对象的副本
//byref：使用proxy对象（默认）



//https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html
//当编译器遇到属性声明（请参阅Objective-C编程语言中的声明属性）时，它会生成与封闭类，类别或协议相关联的描述性元数据。 您可以使用 支持通过类或协议上的名称查找属性的函数来访问此元数据，以@encode字符串获取属性的类型，并将属性的属性列表复制为C字符串数组。 声明的属性列表可用于每个类和协议。

//Property结构 定义了属性描述符的不透明句柄。
//  typedef struct objc_property *Property;
//可以使用函数class_copyPropertyList和protocol_copyPropertyList来取得所有属性的数组
//objc_property_t *class_copyPropertyList(Class cls, unsigned int *outCount)
//objc_property_t *protocol_copyPropertyList(Protocol *proto, unsigned int *outCount)
//可以使用函数property_getName来获得一个属性的名称
//可以使用函数class_getProperty和protocol_getProperty来获得一个property的引用


//可以使用函数property_getAttributes获得一个字符串,改字符串包含了property的名字,@encode字符串,以及其他东西
//这个字符串的结构是这样的:
//" T  @encode(type) ,是否是readonly,是否是copy,等等等,   V实例变量名   "

//R           ---> readonly
//C           ---> copy
//&           ---> retain
//N           ---> nonatomic
//G<name>     ---> 自定义getter方法.(例如,GcustomGetter)
//S<name>     ---> 自定义setter方法.(例如,SCustomSetter:)
//D           ---> @dynamic
//W           ---> __weak
//P           ---> 有资格垃圾回收


////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////


typedef NS_OPTIONS(NSUInteger, XXEncodingType) {
    XXEncodingTypeMask       = 0xFF,
    XXEncodingTypeUnknown    = 0,
    XXEncodingTypeVoid       = 1,
    
    XXEncodingTypeBool       = 2, ///< BOOL
    
    XXEncodingTypeInt8       = 3, ///< char
    XXEncodingTypeUInt8      = 4, ///< unsigned char
    
    XXEncodingTypeInt16      = 5, ///< short
    XXEncodingTypeUInt16     = 6, ///< unsigned short
    
    XXEncodingTypeInt32      = 7, ///< int
    XXEncodingTypeUInt32     = 8, ///< unsigned int
    
    XXEncodingTypeInt64      = 9, ///< long long
    XXEncodingTypeUInt64     = 10, ///< unsigned long long
    
    XXEncodingTypeFloat      = 11, ///< float
    XXEncodingTypeDouble     = 12, ///< double
    XXEncodingTypeLongDouble = 13, ///< long double
    
    XXEncodingTypeObject     = 14, ///< id
    
    XXEncodingTypeClass      = 15, ///< Class
    
    XXEncodingTypeSEL        = 16, ///< SEL
    
    XXEncodingTypeBlock      = 17, ///< block
    
    XXEncodingTypePointer    = 18, ///< void*
    
    XXEncodingTypeStruct     = 19, ///< struct
    
    XXEncodingTypeUnion      = 20, ///< union
    
    XXEncodingTypeCString    = 21, ///< char*
    
    XXEncodingTypeCArray     = 22, ///< char[10] (for example)
    
    
    //////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////
    XXEncodingTypeQualifierMask   = 0xFF00,   ///< mask of qualifier
    XXEncodingTypeQualifierConst  = 1 << 8,  ///< const
    XXEncodingTypeQualifierIn     = 1 << 9,  ///< in
    XXEncodingTypeQualifierInout  = 1 << 10, ///< inout
    XXEncodingTypeQualifierOut    = 1 << 11, ///< out
    XXEncodingTypeQualifierBycopy = 1 << 12, ///< bycopy
    XXEncodingTypeQualifierByref  = 1 << 13, ///< byref
    XXEncodingTypeQualifierOneway = 1 << 14, ///< oneway
    
    
    //////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////
    XXEncodingTypePropertyMask         = 0xFF0000, ///< mask of property
    XXEncodingTypePropertyReadonly     = 1 << 16, ///< readonly
    XXEncodingTypePropertyCopy         = 1 << 17, ///< copy
    XXEncodingTypePropertyRetain       = 1 << 18, ///< retain
    XXEncodingTypePropertyNonatomic    = 1 << 19, ///< nonatomic
    XXEncodingTypePropertyWeak         = 1 << 20, ///< weak
    XXEncodingTypePropertyCustomGetter = 1 << 21, ///< getter=
    XXEncodingTypePropertyCustomSetter = 1 << 22, ///< setter=
    XXEncodingTypePropertyDynamic      = 1 << 23, ///< @dynamic
    
};



XXEncodingType XXEncodingGetType(const char *typeEncoding);






/**
 *  property信息
 */
@interface XXClassPropertyInfo : NSObject

- (instancetype)initWithProperty:(objc_property_t)property;

@property (nonatomic, assign, readonly) objc_property_t property;//property对应的结构体
@property (nonatomic, strong, readonly) NSString *name;//property的名字
@property (nonatomic, assign, readonly) XXEncodingType type;//property的type
@property (nonatomic, strong, readonly) NSString *typeEncoding;//property的@encoding值
@property (nonatomic, strong, readonly) NSString *ivarName;//property的实例变量名
@property (nonatomic, assign, readonly, nullable) Class cls;
@property (nonatomic, strong, readonly, nullable) NSArray<NSString *> *protocols;
@property (nonatomic, assign, readonly) SEL getter;//getter (nonnull)
@property (nonatomic, assign, readonly) SEL setter;//setter (nonnull)

@end


/**
 *  method信息
 */
@interface XXClassMethodInfo : NSObject

- (instancetype)initWithMethod:(Method)method;

@property (nonatomic, assign, readonly) Method method;
@property (nonatomic, strong, readonly) NSString *name;//method的名字
@property (nonatomic, assign, readonly) SEL sel;//method的selecotor
@property (nonatomic, assign, readonly) IMP imp;//method的implementation
@property (nonatomic, strong, readonly) NSString *typeEncoding;//method's parameter and return types
@property (nonatomic, strong, readonly) NSString *returnTypeEncoding;//返回值类型
@property (nullable, nonatomic, strong, readonly) NSArray<NSString *> *argumentTypeEncodings; ///< array of 参数的类型

@end


/**
 *  实例变量信息
 *
 */
@interface XXClassIvarInfo : NSObject

- (instancetype)initWithIvar:(Ivar)ivar;

@property (nonatomic, assign, readonly) Ivar ivar;
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, assign, readonly) ptrdiff_t offset;//ivar的偏移
@property (nonatomic, strong, readonly) NSString *typeEncoding;//ivar的type encoding
@property (nonatomic, assign, readonly) XXEncodingType type;//ivar的type

@end





























/**
 * 一个类的类信息
 */
@interface XXClassInfo : NSObject
@property (nonatomic, assign, readonly) Class cls;
@property (nonatomic, assign, readonly, nullable) Class superCls;
@property (nonatomic, assign, readonly, nullable) Class metaCls;
@property (nonatomic, readonly) BOOL isMeta;
@property (nonatomic, strong, readonly) NSString *name;
@property (nullable, nonatomic, strong, readonly) XXClassInfo *superClassInfo;

//实例变量
@property (nullable, nonatomic, strong, readonly) NSDictionary<NSString *, XXClassIvarInfo *> *ivarInfos;
//methods
@property (nullable, nonatomic, strong, readonly) NSDictionary<NSString *, XXClassMethodInfo *> *methodInfos;
//properties
@property (nullable, nonatomic, strong, readonly) NSDictionary<NSString *, XXClassPropertyInfo *> *propertyInfos;

/**
 *  如果class被改变了(例如,你使用class_addMethod()方法给这个class增加了一个method),你需要调用这个方法去刷新这个classInfo的缓存信息.
 *  在调用这个方法之后,'needUpdate'会返回YES,你需要调用'classInfoWithClass'或者'classInfoWithClassName'来获得更新后的classInfo.
 */
- (void)setNeedUpdate;

/**
 *  如果这个方法返回YES,你需要停止使用该实例,并调用'classInfoWithClass'或者'classInfoWithClassName'来获取更新后的classInfo/
 *  @return 这个classInfo是否需要更新
 */
- (BOOL)needUpdate;

/**
 *  获取指定类的classInfo
 *
 *  @discussion 这个方法将缓存class info和super-class info,在第一次访问这个Class时. 该方法线程安全.
 */
+ (nullable instancetype)classInfoWithClass:(Class)cls;

+ (nullable instancetype)classInfoWithClassName:(NSString *)className;

@end




NS_ASSUME_NONNULL_END
