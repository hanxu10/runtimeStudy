//
//  MYMJSONAdapter.m
//  rumtime
//
//  Created by hanxu on 2017/3/26.
//  Copyright © 2017年 hanxu. All rights reserved.
//

#import "MYMJSONAdapter.h"
#import "MYMModel.h"
#import "MYMReflection.h"
#import <objc/runtime.h>
#import "MYMEXTRuntimeExtensions.h"
#import "MYMEXTScope.h"
#import "MYMTransformerErrorHandling.h"
#import "NSValueTransformer+MYMPredefinedTransformerAdditions.h"
#import "NSDictionary+MYMJSONKeyPath.h"
#import "MYMValueTransformer.h"
NSString * const MYMJSONAdapterErrorDomain = @"MYMJSONAdapterErrorDomain";
const NSInteger MTLJSONAdapterErrorExceptionThrown = 1;
const NSInteger MYMJSONAdapterErrorNoClassFound = 2;
const NSInteger MYMJSONAdapterErrorInvalidJSONDictionary = 3;
const NSInteger MYMJSONAdapterErrorInvalidJSONMapping = 4;
// Associated with the NSException that was caught.
NSString * const MYMJSONAdapterThrownExceptionErrorKey = @"MYMJSONAdapterThrownException";




@interface MYMJSONAdapter ()

@property (nonatomic, strong ,readonly)Class modelClass;

/*------------------这几个都是用来缓存的----------------------------------*/
@property (nonatomic, copy, readonly) NSDictionary *JSONKeyPathsByPropertyKey;

@property (nonatomic, copy, readonly) NSDictionary *valueTransformersByPropertyKey;

// Used to cache the JSON adapters returned by -JSONAdapterForModelClass:error:.
@property (nonatomic, strong, readonly) NSMapTable *JSONAdaptersByModelClass;
/*--------------------------------------------------------------------*/

// 如果+ classForParsingJSONDictionary：返回与该适配器初始化的模型类不同的模型类，请使用此方法来获取适当适配器的缓存实例。
// modelClass - 从中解析JSON的类。 该类必须符合<MTLJSONSerializing>。 这个说法不能是零。
// error - 如果不是NULL，这可能会被设置为在初始化适配器期间发生的错误。
// 返回一个用于modelClass的JSON适配器，创建必要的一个。 如果不能创建适配器，则返回nil。
- (MYMJSONAdapter *)JSONAdapterForModelClass:(Class)modelClass error:(NSError **)error;

// 收集给定类所需的所有值变换器。
// modelClass - 从中解析JSON的类。 该类必须符合<MTLJSONSerializing>。 这个参数不能是零。
// 返回一个具有modelClass属性的字典，该属性需要转换为键，值变换器为值。
+ (NSDictionary *)valueTransformersForModelClass:(Class)modelClass;

@end


@implementation MYMJSONAdapter
#pragma mark - 便利的方法
+ (id)modelOfClass:(Class)modelClass fromJSONDictionary:(NSDictionary *)JSONDictionary error:(NSError *__autoreleasing *)error {
    MYMJSONAdapter *adapter = [[self alloc] initWithModelClass:modelClass];
    return [adapter modelFromJSONDictionary:JSONDictionary error:error];
}

+ (NSArray *)modelsOfClass:(Class)modelClass fromJSONArray:(NSArray *)JSONArray error:(NSError *__autoreleasing *)error {
    if (JSONArray == nil || ![JSONArray isKindOfClass:[NSArray class]]) {
        if (error != NULL) {
            NSDictionary *userInfo = @{
                                       NSLocalizedDescriptionKey: NSLocalizedString(@"Missing JSON array", @""),
                                       NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"%@ could not be created because an invalid JSON array was provided: %@", @""), NSStringFromClass(modelClass), JSONArray.class],
                                       };
            *error = [NSError errorWithDomain:MYMJSONAdapterErrorDomain code:MYMJSONAdapterErrorInvalidJSONDictionary userInfo:userInfo];
        }
        return nil;
    }
    
    NSMutableArray *models = [NSMutableArray arrayWithCapacity:JSONArray.count];
    for (NSDictionary *JSONDictionary in JSONArray) {
        MYMModel *model = [self modelOfClass:modelClass fromJSONDictionary:JSONDictionary error:error];
        if (model == nil) {
            return nil;
        }
        [models addObject:model];
    }
    return models;
}

+ (NSDictionary *)JSONDictionaryFromModel:(id<MYMJSONSerializing>)model error:(NSError *__autoreleasing *)error {
    MYMJSONAdapter *adapter = [[self alloc] initWithModelClass:model.class];
    return [adapter JSONDictionaryFromModel:model error:error];
}

+ (NSArray *)JSONArrayFromModels:(NSArray *)models error:(NSError *__autoreleasing *)error {
    NSParameterAssert(models != nil);
    NSParameterAssert([models isKindOfClass:[NSArray class]]);
    
    NSMutableArray *JSONArray = [NSMutableArray arrayWithCapacity:models.count];
    for (MYMModel<MYMJSONSerializing> *model in models) {
        NSDictionary *JSONDictionary = [self JSONDictionaryFromModel:model error:error];
        if (JSONDictionary == nil) {
            return nil;
        }
        [JSONArray addObject:JSONDictionary];
    }
    return JSONArray;
}

#pragma mark - 生命周期

- (instancetype)init {
    NSAssert(NO, @"%@ must be initialized with a model class", self.class);
    return nil;
}

- (id)initWithModelClass:(Class)modelClass {
    NSParameterAssert(modelClass != nil);
    NSParameterAssert([modelClass conformsToProtocol:@protocol(MYMJSONSerializing)]);
    
    self = [super init];
    if (self == nil) {
        return nil;
    }
    
    _modelClass = modelClass;
    _JSONKeyPathsByPropertyKey = [modelClass JSONKeyPathsByPropertyKey];
    
//    + (NSDictionary *)JSONKeyPathsByPropertyKey
//    {
//        return [@{@"music"    : @"music_info",
//                  @"username" : @"user_name",
//                  @"schema"   : @"user_schema"} apiPropertyKey];
//    }
    
    //检查字典中的映射key是否都能对应上model中的属性
    NSSet *propertyKeys = [self.modelClass propertyKeys];
    for (NSString *mappedPropertyKey in _JSONKeyPathsByPropertyKey) {
        if (![propertyKeys containsObject:mappedPropertyKey]) {
            NSAssert(NO, @"%@ is not a property of %@", mappedPropertyKey, modelClass);
            return nil;
        }
        
        id value = _JSONKeyPathsByPropertyKey[mappedPropertyKey];
        
        if ([value isKindOfClass:[NSArray class]]) {
            for (NSString *keyPath in value) {
                if ([keyPath isKindOfClass:[NSString class]]) {
                    continue;
                }
                NSAssert(NO, @"%@ must either map to a JSON key path or a JSON array of key paths, got: %@", mappedPropertyKey, value);
                return nil;
            }
        } else if (![value isKindOfClass:[NSString class]]){
            NSAssert(NO, @"%@ must either map to a JSON path or a JSON array of key paths, got: %@.", mappedPropertyKey, value);
            return nil;
        }
    }
    
    _valueTransformersByPropertyKey = [[self class] valueTransformersForModelClass:modelClass];
    
    _JSONAdaptersByModelClass = [NSMapTable strongToStrongObjectsMapTable];
    
    return self;
    
}

#pragma mark - 序列化

- (NSDictionary *)JSONDictionaryFromModel:(id<MYMJSONSerializing>)model error:(NSError *__autoreleasing *)error {
    NSParameterAssert(model != nil);
    NSParameterAssert([model isKindOfClass:self.modelClass]);
    
    //如果传进来的model与初始化时传入的model不相同
    if (model.class != self.modelClass) {
        MYMJSONAdapter *otherAdapter = [self JSONAdapterForModelClass:model.class error:error];
        return [otherAdapter JSONDictionaryFromModel:model error:error];
    }
    
    //serializablePropertyKeys 默认是把下面这个方法中的keys都传进来了。
    //    + (NSDictionary *)JSONKeyPathsByPropertyKey
    //    {
    //        return [@{@"music"    : @"music_info",
    //                  @"username" : @"user_name",
    //                  @"schema"   : @"user_schema"} apiPropertyKey];
    //    }
    NSSet *propertyKeysToSerialize = [self serializablePropertyKeys:[NSSet setWithArray:self.JSONKeyPathsByPropertyKey.allKeys] forModel:model];
    
    //根据一堆keys获取字典的子集
    NSDictionary *dictionaryValue = [model.dictionaryValue dictionaryWithValuesForKeys:propertyKeysToSerialize.allObjects];
    
    NSMutableDictionary *JSONDictionary = [[NSMutableDictionary alloc] initWithCapacity:dictionaryValue.count];
    
    __block BOOL success = YES;
    __block NSError *tmpError = nil;
    
    [dictionaryValue enumerateKeysAndObjectsUsingBlock:^(NSString *propertyKey, id value, BOOL *stop) {
        id JSONKeyPaths = self.JSONKeyPathsByPropertyKey[propertyKey];
        if (JSONKeyPaths == nil) {
            return ;
        }
        
        NSValueTransformer *transformer = self.valueTransformersByPropertyKey[propertyKey];
        if ([transformer.class allowsReverseTransformation] ) {
            if ([value isEqual:[NSNull null]]) {
                value = nil;
            }
            
            if ([transformer respondsToSelector:@selector(reverseTransformedValue:success:error:)]) {
                id<MYMTransformerErrorHandling> errorHandlingTransformer = (id)transformer;
                
                value = [errorHandlingTransformer reverseTransformedValue:value success:&success error:&tmpError];
                
                if (!success) {
                    *stop = YES;
                    return;
                }
            } else {
                value = [transformer reverseTransformedValue:value] ?: NSNull.null;
            }
        }
        
//    keypath:a.b.c
//    json[a][b][c]
//    a:{
//        b:{
//            
//        }
//    }
        
        void (^createComponents)(id, NSString *) = ^ (id obj, NSString *keyPath) {
            NSArray *keyPathComponents = [keyPath componentsSeparatedByString:@"."];
            
            for (NSString *component in keyPathComponents) {
                if ([obj valueForKey:component] == nil) {
                    [obj setValue:[NSMutableDictionary dictionary] forKey:component];
                }
                obj = [obj valueForKey:component];
            }
        };
        
        if ([JSONKeyPaths isKindOfClass:NSString.class]) {
            createComponents(JSONDictionary, JSONKeyPaths);
            [JSONDictionary setValue:value forKey:JSONKeyPaths];
        }
        
        if ([JSONKeyPaths isKindOfClass:NSArray.class]) {
            for (NSString *JSONKeyPath in JSONKeyPaths ) {
                createComponents(JSONDictionary, JSONKeyPath);
                [JSONDictionary setValue:value[JSONKeyPath] forKey:JSONKeyPath];
            }
        }
        
    }];
    
    if (success) {
        return JSONDictionary;
    } else {
        if (error != NULL) {
            *error = tmpError;
        }
        return nil;
    }
}

- (id)modelFromJSONDictionary:(NSDictionary *)JSONDictionary error:(NSError *__autoreleasing *)error {
    if ([self.modelClass respondsToSelector:@selector(classForParsingJSONDictionary:)]) {
        //处理类簇.
        Class class = [self.modelClass classForParsingJSONDictionary:JSONDictionary];
        if (class == nil) {
            if (error != NULL) {
                NSDictionary *userInfo = @{
                                           NSLocalizedDescriptionKey: NSLocalizedString(@"Could not parse JSON", @""),
                                           NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"No model class could be found to parse the JSON dictionary.", @"")
                                           };
                
                *error = [NSError errorWithDomain:MYMJSONAdapterErrorDomain code:MYMJSONAdapterErrorNoClassFound userInfo:userInfo];
            }
            
            return nil;
        }
        
        if (class != self.modelClass) {
            NSAssert([class conformsToProtocol:@protocol(MYMJSONSerializing)], @"Class %@ returned from +classForParsingJSONDictionary: does not conform to <MYMJSONSerializing>",class);
            MYMJSONAdapter *otherAdapter = [self JSONAdapterForModelClass:class error:error];
            return [otherAdapter modelFromJSONDictionary:JSONDictionary error:error];
        }
    }
    
    NSMutableDictionary *dictionaryValue = [[NSMutableDictionary alloc] initWithCapacity:JSONDictionary.count];
    for (NSString *propertyKey in [self.modelClass propertyKeys]) {
        id JSONKeyPaths = self.JSONKeyPathsByPropertyKey[propertyKey];
        if (JSONKeyPaths == nil) {
            continue;
        }
        
        id value;
        
        if ([JSONKeyPaths isKindOfClass:NSArray.class]) {
            NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
            
            for (NSString *keyPath in JSONKeyPaths) {
                BOOL success = NO;
                id value = [JSONDictionary mym_valueForJSONKeyPath:keyPath success:&success error:error];
                if (!success) {
                    return nil;
                }
                if (value != nil) {
                    dictionary[keyPath] = value;
                }
            }
            
            value = dictionary;
        } else {
            BOOL success = NO;
            value = [JSONDictionary mym_valueForJSONKeyPath:JSONKeyPaths success:&success error:error];
            if (!success) {
                return nil;
            }
        }
        
        if (value == nil) {
            continue;
        }
        
        @try {
            NSValueTransformer *transformer = self.valueTransformersByPropertyKey[propertyKey];
            if (transformer != nil) {
                if ([value isEqual:[NSNull null]]) {
                    value = nil;
                }
                
                if ([transformer respondsToSelector:@selector(transformedValue:success:error:)]) {
                    id<MYMTransformerErrorHandling> errorHandlingTransformer = (id)transformer;
                    BOOL success = YES;
                    value = [errorHandlingTransformer transformedValue:value success:&success error:error];
                    if (!success) {
                        return nil;
                    }
                } else {
                    value = [transformer transformedValue:value];
                }
                
                if (value == nil) {
                    value = NSNull.null;
                }
            }
            dictionaryValue[propertyKey] = value;
            
        } @catch (NSException *ex) {
            NSLog(@"*** Caught exception %@ parsing JSON key path \"%@\" from: %@", ex, JSONKeyPaths, JSONDictionary);
            
            // Fail fast in Debug builds.
            #if DEBUG
            @throw ex;
            #else
            if (error != NULL) {
                NSDictionary *userInfo = @{
                                           NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Caught exception parsing JSON key path \"%@\" for model class: %@", JSONKeyPaths, self.modelClass],
                                           NSLocalizedRecoverySuggestionErrorKey: ex.description,
                                           NSLocalizedFailureReasonErrorKey: ex.reason,
                                           MYMJSONAdapterThrownExceptionErrorKey: ex
                                           };
                
                *error = [NSError errorWithDomain:MTLJSONAdapterErrorDomain code:MYMJSONAdapterErrorExceptionThrown userInfo:userInfo];
            }
            
            return nil;
            #endif
        }
    }
    
    id model = [self.modelClass modelWithDictionary:dictionaryValue error:error];
    return [model validate:error] ? model : nil;
}

- (MYMJSONAdapter *)JSONAdapterForModelClass:(Class)modelClass error:(NSError *__autoreleasing *)error {
    NSParameterAssert(modelClass != nil);
    NSParameterAssert([modelClass conformsToProtocol:@protocol(MYMJSONSerializing)]);
    
    @synchronized (self) {
        MYMJSONAdapter *result = [self.JSONAdaptersByModelClass objectForKey:modelClass];
        if (result != nil) {
            return result;
        }
        result = [[self.class alloc] initWithModelClass:modelClass];
        if (result != nil) {
            [self.JSONAdaptersByModelClass setObject:result forKey:modelClass];
        }
        return result;
    }
}

- (NSSet *)serializablePropertyKeys:(NSSet *)propertyKeys forModel:(id<MYMJSONSerializing>)model {
    return propertyKeys;
}

+ (NSValueTransformer *)transformerForModelPropertiesOfClass:(Class)modelClass {
    NSParameterAssert(modelClass != nil);
    
    SEL selector = MYMSelectorWithKeyPattern(NSStringFromClass(modelClass), "JSONTransformer");
    if (![self respondsToSelector:selector]) {
        return nil;
    }
    
    IMP imp = [self methodForSelector:selector];
    NSValueTransformer * (*function)(id, SEL) = (__typeof__(function))imp;
    NSValueTransformer *result = function(self, selector);
    
    return result;
}

+ (NSValueTransformer *)transformerForModelPropertiesOfObjCType:(const char *)objCType {
    NSParameterAssert(objCType != NULL);
    
    if (strcmp(objCType, @encode(BOOL)) == 0) {
        return [NSValueTransformer valueTransformerForName:MYMBooleanValueTransformerName];
    }
    
    return nil;
}

+ (NSDictionary *)valueTransformersForModelClass:(Class)modelClass {
    NSParameterAssert(modelClass != nil);
    NSParameterAssert([modelClass conformsToProtocol:@protocol(MYMJSONSerializing)]);
    
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    
    for (NSString *key in [modelClass propertyKeys]) {
        SEL selector = MYMSelectorWithKeyPattern(key, "JSONTransformer");
        //1.首先用model 的  XXXJSONTransformer来获取transfomer
        if ([modelClass respondsToSelector:selector]) {
            IMP imp = [modelClass methodForSelector:selector];
            NSValueTransformer* (*function)(id, SEL) = (__typeof__(function))imp;
            NSValueTransformer *transformer = function(modelClass, selector);
            if (transformer != nil) {
                result[key] = transformer;
            }
            continue;
        }
        //2.用model 的 JSONTransformerForKey: 来获取
        if ([modelClass respondsToSelector:@selector(JSONTransformerForKey:)]) {
            NSValueTransformer *transformer = [modelClass JSONTransformerForKey:key];
            
            if (transformer != nil) {
                result[key] = transformer;
                continue;
            }
            
        }
        
        objc_property_t property = class_getProperty(modelClass, key.UTF8String);
        
        if (property == NULL) {
            continue;
        }
        
        mym_propertyAttributes *attributes = mym_copyPropertyAttributes(property);
        @onExit {
            free(attributes);
        };
        
        NSValueTransformer *transformer = nil;
        
        //3.根据是否是id类型来获取
        if (*(attributes->type) == *(@encode(id))) {
            //3.1是对象类型
            Class propertyClass = attributes->objectClass;
            
            if (propertyClass != nil) {
                transformer = [self transformerForModelPropertiesOfClass:propertyClass];
            }
            
            // For user-defined MYMModel, try parse it with dictionaryTransformer.
            if (nil == transformer && [propertyClass conformsToProtocol:@protocol(MYMJSONSerializing)]) {
                transformer = [self dictionaryTransformerWithModelClass:propertyClass];
            }
            
            if (transformer == nil) {
                transformer = [NSValueTransformer mym_validatingTransformerForClass:propertyClass ?: [NSObject class]];
            }
        } else {
            //3.2是基本类型
            transformer = [self transformerForModelPropertiesOfObjCType:attributes->type] ?: [NSValueTransformer mym_validatingTransformerForClass:[NSValue class]];
        }
        if (transformer != nil) {
            result[key] = transformer;
        }
    }
    return result;

}

@end





@implementation MYMJSONAdapter (ValueTransformers)

+ (NSValueTransformer<MYMTransformerErrorHandling> *)dictionaryTransformerWithModelClass:(Class)modelClass {
    NSParameterAssert([modelClass conformsToProtocol:@protocol(MYMModel)]);
    NSParameterAssert([modelClass conformsToProtocol:@protocol(MYMJSONSerializing)]);
    
    __block MYMJSONAdapter *adapter;
    
    return [MYMValueTransformer transformerUsingForwardBlock:^id(id JSONDictionary, BOOL *success, NSError *__autoreleasing *error) {
        if (JSONDictionary == nil) {
            return nil;
        }
        
        if (![JSONDictionary isKindOfClass:[NSDictionary class]]) {
            if (error != NULL) {
                NSDictionary *userInfo = @{
                                           NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert JSON dictionary to model object", @""),
                                           NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected an NSDictionary, got: %@", @""), JSONDictionary],
                                           MYMTransformerErrorHandlingInputValueErrorKey : JSONDictionary
                                           };
                
                *error = [NSError errorWithDomain:MYMTransformerErrorHandlingErrorDomain code:MYMTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
            }
            *success = NO;
            return nil;
        }
        
        if (!adapter) {
            adapter = [[self alloc] initWithModelClass:modelClass];
        }
        id model = [adapter modelFromJSONDictionary:JSONDictionary error:error];
        if (model == nil) {
            *success = NO;
        }
        return model;
        
        
    } reverseBlock:^id(id model, BOOL *success, NSError *__autoreleasing *error) {
        
        if (model == nil) return nil;
        
        if (![model conformsToProtocol:@protocol(MYMModel)] || ![model conformsToProtocol:@protocol(MYMJSONSerializing)]) {
            if (error != NULL) {
                NSDictionary *userInfo = @{
                                           NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert model object to JSON dictionary", @""),
                                           NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected a MTLModel object conforming to <MTLJSONSerializing>, got: %@.", @""), model],
                                           MYMTransformerErrorHandlingInputValueErrorKey : model
                                           };
                
                *error = [NSError errorWithDomain:MYMTransformerErrorHandlingErrorDomain code:MYMTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
            }
            *success = NO;
            return nil;
        }
        
        if (!adapter) {
            adapter = [[self alloc] initWithModelClass:modelClass];
        }
        NSDictionary *result = [adapter JSONDictionaryFromModel:model error:error];
        
        
        if (result == nil) {
            *success = NO;
        }
        
        return result;
        
    }];
}

+ (NSValueTransformer<MYMTransformerErrorHandling> *)arrayTransformerWithModelClass:(Class)modelClass {
    id<MYMTransformerErrorHandling> dictionaryTransformer = [self dictionaryTransformerWithModelClass:modelClass];
    
    return [MYMValueTransformer transformerUsingForwardBlock:^id(NSArray *dictionaries, BOOL *success, NSError *__autoreleasing *error) {
        
        if (dictionaries == nil) {
            return nil;
        }
        
        if (![dictionaries isKindOfClass:[NSArray class]]) {
            if (error != NULL) {
                NSDictionary *userInfo = @{
                                           NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert JSON array to model array", @""),
                                           NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected an NSArray, got: %@.", @""), dictionaries],
                                           MYMTransformerErrorHandlingInputValueErrorKey : dictionaries
                                           };
                
                *error = [NSError errorWithDomain:MYMTransformerErrorHandlingErrorDomain code:MYMTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
            }
            *success = NO;
            return nil;
        }
        
        NSMutableArray *models = [NSMutableArray arrayWithCapacity:dictionaries.count];
        for (id JSONDictionary in dictionaries) {
            if (JSONDictionary == NSNull.null) {
                [models addObject:NSNull.null];
                continue;
            }
            if (![JSONDictionary isKindOfClass:[NSDictionary class]]) {
                if (error != NULL) {
                    NSDictionary *userInfo = @{

                                               NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert JSON array to model array", @""),
                                               NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected an NSDictionary or an NSNull, got: %@.", @""), JSONDictionary],
                                               MYMTransformerErrorHandlingInputValueErrorKey : JSONDictionary
                                               };
                    
                    *error = [NSError errorWithDomain:MYMTransformerErrorHandlingErrorDomain code:MYMTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
                }
                *success = NO;
                return nil;
            }
            
            id model = [dictionaryTransformer transformedValue:JSONDictionary success:success error:error];
            if (*success == NO) {
                return nil;
            }
            
            if (model == nil) {
                continue;
            }
            [models addObject:model];
        }
        return models;
        
    } reverseBlock:^id(NSArray *models, BOOL *success, NSError *__autoreleasing *error) {
        if (models == nil) return nil;
        
        if (![models isKindOfClass:NSArray.class]) {
            if (error != NULL) {
                NSDictionary *userInfo = @{
                                           NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert model array to JSON array", @""),
                                           NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected an NSArray, got: %@.", @""), models],
                                           MYMTransformerErrorHandlingInputValueErrorKey : models
                                           };
                
                *error = [NSError errorWithDomain:MYMTransformerErrorHandlingErrorDomain code:MYMTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
            }
            *success = NO;
            return nil;
        }
        
        NSMutableArray *dictionaries = [NSMutableArray arrayWithCapacity:models.count];
        for (id model in models) {
            if (model == NSNull.null) {
                [dictionaries addObject:NSNull.null];
                continue;
            }
            
            if (![model isKindOfClass:[MYMModel class]]) {
                if (error != NULL) {
                    NSDictionary *userInfo = @{
                                               NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert JSON array to model array", @""),
                                               NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected a MTLModel or an NSNull, got: %@.", @""), model],
                                               MYMTransformerErrorHandlingInputValueErrorKey : model
                                               };
                    
                    *error = [NSError errorWithDomain:MYMTransformerErrorHandlingErrorDomain code:MYMTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
                }
                *success = NO;
                return nil;
            }
            
            NSDictionary *dict = [dictionaryTransformer reverseTransformedValue:model success:success error:error];
            if (*success == NO) {
                return nil;
            }
            if (dict == nil) {
                continue;
            }
            [dictionaries addObject:dict];
        }
        return dictionaries;
    }];
}

+ (NSValueTransformer *)NSURLJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MYMURLValueTransformerName];
}
@end


