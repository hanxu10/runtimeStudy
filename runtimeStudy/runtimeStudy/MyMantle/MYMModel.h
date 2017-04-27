//
//  MyMModel.h
//  rumtime
//
//  Created by hanxu on 2017/3/8.
//  Copyright © 2017年 hanxu. All rights reserved.
//

#import <Foundation/Foundation.h>

//属性存储行为，决定这个属性如何被copy，compare，persist。
typedef enum : NSUInteger {
    MYMPropertyStorageNone,
    //该属性不包含在-description,-hash, or anything else.
    MYMPropertyStorageTransitory,
    //暂时的，包含在一次性操作中，如：-copy and -dictionaryValue，但是不影响-isEqual: or -hash.它可能随时消失
    MYMPropertyStoragePermanent
    //永久的，包含在serialization（如 ‘NSCoding’）和equality中
}MYMPropertyStorage;


//这是个协议，定义了一个类与adapter进行交互需要的最少操作；有些情况下无法继承MTLModel，得使用协议。
//希望实现自己的适配器的客户端应针对符合此协议的类，而不是MTLModel的子类，以确保最大的兼容性。
@protocol MYMModel <NSObject, NSCopying>

/// 使用键值编码初始化接收器的新实例，设置给定字典中的键和值。
/// dictionaryValue - 要在实例上设置的属性键和值。 任何NSNull值将在使用前转换为nil。 对于给定的所有属性来说，KVC验证方法将自动调用。
/// 返回初始化的模型对象，如果验证失败，则返回nil。
+ (instancetype)modelWithDictionary:(NSDictionary *)dictionaryValue error:(NSError **)error;


/// 表示接收器属性的字典。
/// 将对应于所有+ propertyKeys的值组合成字典，任何nil值由NSNull表示。该属性不会是nil
@property (nonatomic, copy, readonly) NSDictionary *dictionaryValue;

/// 使用键值编码初始化接收器的新实例，设置给定字典中的键和值。
/// 子类实现可以复写此方法，调用super实现，以便在反序列化之后执行进一步的处理和初始化。
/// dictionaryValue - 如果为nil，此方法等效于-init。
- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError **)error;


/// 将接收器上给定key的值与来自给定模型对象的相同键的值进行合并，为其他模型对象赋予优先级。
- (void)mergeValueForKey:(NSString *)key fromModel:(id<MYMModel>)model;

/// 返回所有@property声明的键，除了没有ivars的`readonly`属性，或者MTLModel本身的属性。
+ (NSSet *)propertyKeys;

/// 验证这个模型
/// error - 如果不为NULL，则它可能被设置为在验证期间发生的任何错误；
/// 如果模型有效，则返回YES，如果验证失败，则返回NO。
- (BOOL)validate:(NSError **)error;

@end

/// 模型对象的抽象基类，使用反射来提供合理的默认行为。
/// The default implementations of <NSCopying>, -hash, and -isEqual: make use of
/// the +propertyKeys method.
@interface MYMModel : NSObject <MYMModel>

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError **)error;
- (instancetype)init;

/// 默认情况下，此方法查找`-merge <Key> FromModel：`方法，如果找到，则调用它。 如果没有找到，并且`model`不是nil，给定键的值取自`model`。
- (void)mergeValueForKey:(NSString *)key fromModel:(id<MYMModel>)model;

/// 将给定模型对象的值合并到接收器中，使用-mergeValueForKey：fromModel：对于+ propertyKeys中的每个键。
/// `model`必须是接收者类的实例或其子类。
- (void)mergeValuesForKeysFromModel:(id<MYMModel>)model;


/// 给定键的存储行为。
/// 对于只读且不由实例变量支持的属性，缺省实现返回MTLPropertyStorageNone,其他的返回MTLPropertyStoragePermanent。
/// 子类通过返回MTLPropertyStorageTransitory来阻止MTLModel解析循环引用。
+ (MYMPropertyStorage)storageBehaviorForPropertyWithKey:(NSString *)propertyKey;


/// 默认实现是比较两个模型的+storageBehaviorForPropertyWithKey:返回MTLPropertyStoragePermanent的所有属性
- (BOOL)isEqual:(id)object;

/// A string that describes the contents of the receiver.
///
/// The default implementation is based on the receiver's class and all its
/// properties for which +storageBehaviorForPropertyWithKey: returns
/// MTLPropertyStoragePermanent.
- (NSString *)description;

@end


@interface MYMModel (Validation)

/// Validates the model.
/// 默认实现只是用所有的 + propertyKeys及其当前值来调用-validateValue：forKey：error：。 如果-validateValue：forKey：error：返回一个新值，该属性设置为该新值。
/// 如果模型有效则返回YES，如果验证失败则返回NO。
- (BOOL)validate:(NSError **)error;

@end
