//
//  MYMJSONAdapter.h
//  rumtime
//
//  Created by hanxu on 2017/3/26.
//  Copyright © 2017年 hanxu. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MYMModel;
@protocol MYMTransformerErrorHandling;

@protocol MYMJSONSerializing <MYMModel>
@required

///  指定如何映射property到JSON中的keypath
///  例子：
///
///     + (NSDictionary *)JSONKeyPathsByPropertyKey {
///         return @{
///             @"name": @"POI.name",
///             @"point": @[ @"latitude", @"longitude" ],
///             @"starred": @"starred"
///         };
///     }
///
/// `starred`   属性 对应 `JSONDictionary[@"starred"]`,
/// `name`      属性 对应 `JSONDictionary[@"POI"][@"name"]`
/// `point`     属性 对应 一个字典 @{
///                                 @"latitude": JSONDictionary[@"latitude"],
///                                 @"longitude": JSONDictionary[@"longitude"]
///                              }
+ (NSDictionary *)JSONKeyPathsByPropertyKey;


@optional


///指定如何将JSON值转换为给定的属性键。 如果可逆，变压器也将用于将属性值转换回JSON。
///如果接收者实现了一个`+ <key> JSONTransformer`方法，那么MTLJSONAdapter将会使用该方法的结果。
///返回值变换器，如果不执行转换，则返回零。
+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key;



///重写该方法，根据提供的字典中的信息，将receiver解析为不同的类。
///这对于类集群来说是非常有用的，其中抽象基类将被传入 - [MTLJSONAdapter initWithJSONDictionary：modelClass：]，但是一个子类应该被实例化。
///
/// JSONDictionary - 将被解析的JSON字典。
///
///返回应该被解析的类（可能是接收者），或者无法中止解析（例如，如果数据无效）。
+ (Class)classForParsingJSONDictionary:(NSDictionary *)JSONDictionary;
@end




/// The domain for errors originating from MYMJSONAdapter.
extern NSString * const MYMJSONAdapterErrorDomain;

/// +classForParsingJSONDictionary: returned nil for the given dictionary.
extern const NSInteger MYMJSONAdapterErrorNoClassFound;

/// The provided JSONDictionary is not valid.
extern const NSInteger MYMJSONAdapterErrorInvalidJSONDictionary;

/// The model's implementation of +JSONKeyPathsByPropertyKey included a key which
/// does not actually exist in +propertyKeys.
extern const NSInteger MYMJSONAdapterErrorInvalidJSONMapping;

/// An exception was thrown and caught.
extern const NSInteger MYMJSONAdapterErrorExceptionThrown;

/// Associated with the NSException that was caught.
extern NSString * const MYMJSONAdapterThrownExceptionErrorKey;





@interface MYMJSONAdapter : NSObject
//字典转模型
+ (id)modelOfClass:(Class)modelClass fromJSONDictionary:(NSDictionary *)JSONDictionary error:(NSError **)error;
+ (NSArray *)modelsOfClass:(Class)modelClass fromJSONArray:(NSArray *)JSONArray error:(NSError **)error;

//模型转字典
+ (NSDictionary *)JSONDictionaryFromModel:(id<MYMJSONSerializing>)model error:(NSError **)error;
+ (NSArray *)JSONArrayFromModels:(NSArray *)models error:(NSError **)error;


//初始化一个适配器
- (id)initWithModelClass:(Class)modelClass;

- (id)modelFromJSONDictionary:(NSDictionary *)JSONDictionary error:(NSError **)error;
- (NSDictionary *)JSONDictionaryFromModel:(id<MYMJSONSerializing>)model error:(NSError **)error;


///过滤用于序列化给定模型的属性键。
/// propertyKeys - “model”提供映射的属性键。
/// model - 模型被序列化。
///子类可以覆盖此方法，以确定在串行化`model`时应使用哪些属性键。 例如，该方法可用于创建服务器端资源的更有效的更新。
///默认实现只是返回`propertyKeys`。
///返回应该为给定模型序列化的propertyKeys的子集。
//
// 在把模型转成字典时，可以设置哪些属性要转化到字典中
- (NSSet *)serializablePropertyKeys:(NSSet *)propertyKeys forModel:(id<MYMJSONSerializing>)model;

///应该用于给定类的属性的可选值变换器。
///由模型的+ JSONTransformerForKey：方法返回的值变换器优先于此方法返回的值。
///默认实现在接收器上调用`+ <class> JSONTransformer`（如果它被实现）。 它通过+ NSURLJSONTransformer支持NSURL转换。
/// modelClass - 要序列化的属性的类。 该属性不能为零。
///返回值变换器，如果不使用转换，则返回零。
+ (NSValueTransformer *)transformerForModelPropertiesOfClass:(Class)modelClass;



/// A value transformer that should be used for a properties of the given
/// primitive type.
///
/// If `objCType` matches @encode(id), the value transformer returned by
/// +transformerForModelPropertiesOfClass: is used instead.
///
/// The default implementation transforms properties that match @encode(BOOL)
/// using the MTLBooleanValueTransformerName transformer.
///
/// objCType - The type encoding for the value of this property. This is the type
///            as it would be returned by the @encode() directive.
///
/// Returns a value transformer or nil if no transformation should be used.
+ (NSValueTransformer *)transformerForModelPropertiesOfObjCType:(const char *)objCType;


@end


@interface MYMJSONAdapter (ValueTransformers)

/// Creates a reversible transformer to convert a JSON dictionary into a MTLModel
/// object, and vice-versa.
///
/// modelClass - The MTLModel subclass to attempt to parse from the JSON. This
///              class must conform to <MTLJSONSerializing>. This argument must
///              not be nil.
///
/// Returns a reversible transformer which uses the class of the receiver for
/// transforming values back and forth.
+ (NSValueTransformer<MYMTransformerErrorHandling> *)dictionaryTransformerWithModelClass:(Class)modelClass;

/// Creates a reversible transformer to convert an array of JSON dictionaries
/// into an array of MTLModel objects, and vice-versa.
///
/// modelClass - The MTLModel subclass to attempt to parse from each JSON
///              dictionary. This class must conform to <MTLJSONSerializing>.
///              This argument must not be nil.
///
/// Returns a reversible transformer which uses the class of the receiver for
/// transforming array elements back and forth.
+ (NSValueTransformer<MYMTransformerErrorHandling> *)arrayTransformerWithModelClass:(Class)modelClass;

/// This value transformer is used by MTLJSONAdapter to automatically convert
/// NSURL properties to JSON strings and vice versa.
+ (NSValueTransformer *)NSURLJSONTransformer;

@end
