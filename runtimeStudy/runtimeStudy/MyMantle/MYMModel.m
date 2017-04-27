//
//  MyMModel.m
//  rumtime
//
//  Created by hanxu on 2017/3/8.
//  Copyright © 2017年 hanxu. All rights reserved.
//

#import "MYMModel.h"
#import <objc/runtime.h>
#import "MYMEXTScope.h"
#import "MYMReflection.h"
#import "MYMEXTRuntimeExtensions.h"
//用于缓存在+ propertyKeys中执行的反射。
static void *MYMModelCachedPropertyKeysKey = &MYMModelCachedPropertyKeysKey;

//用在+generateAndCachePropertyKeys方法中，缓存permanent Proprety Keys 和 Transitory Property Keys
static void *MYMModelCachedPermanentPropertyKeysKey = &MYMModelCachedPermanentPropertyKeysKey;
static void *MYMModelCachedTransitoryPropertyKeysKey = &MYMModelCachedTransitoryPropertyKeysKey;


// 验证对象的值并在必要时设置它。
// obj - 要验证其值的对象。 此值不能为零。
// key - `obj`s属性之一的名称。 此值不能为零。
// value - 由`key`标识的属性的新值。
// forceUpdate - 如果设置为“YES”，即使验证它没有更改，该值也会被更新。
// error - 如果不为NULL，则可以将其设置为验证期间发生的任何错误。

// 如果可以验证和设置“value”，则返回YES，如果发生错误，则返回NO。
static BOOL MYMValidateAndSetValue(id obj, NSString *key, id value, BOOL forceUpdate, NSError **error) {
    __autoreleasing id validatedValue = value;
    
    @try {
        if (![obj validateValue:&validatedValue forKey:key error:error]) {
            return NO;
        }
        if (forceUpdate || value != validatedValue) {
            [obj setValue:validatedValue forKey:key];
        }
        return YES;
    } @catch (NSException *ex) {
        NSLog(@"*** Caught exception setting key \"%@\" : %@", key, ex);
        
#if DEBUG
        @throw ex;
#else
        if (error != NULL) {
            *error = [NSError mtl_modelErrorWithException:ex];
        }
        return NO;
#endif

    }
}



@interface MYMModel ()
// Returns a set of all property keys for which
// +storageBehaviorForPropertyWithKey returned MTLPropertyStorageTransitory.
+ (NSSet *)transitoryPropertyKeys;

//用+storageBehaviorForPropertyWithKey挨个探测+propertyKeys返回的keys，并缓存结果。
+ (void)generateAndCacheStorageBehaviors;

//+storageBehaviorForPropertyWithKey 返回 MTLPropertyStoragePermanent的属性的key。
+ (NSSet *)permanentPropertyKeys;

//枚举接收器的类层次结构的所有属性，从接收器开始，并继续直到（但不包括）MTLModel。
+ (void)enumeratePropertiesUsingBlock:(void(^)(objc_property_t property, BOOL *stop))block;
@end


@implementation MYMModel
#pragma mark Lifecycle

+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary error:(NSError **)error {
    return [[self alloc] initWithDictionary:dictionary error:error];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary error:(NSError **)error {
    self = [self init];
    if (self == nil) {
        return nil;
    }
    for (NSString *key in dictionary) {
        __autoreleasing id value = [dictionary valueForKey:key];
        
        if ([value isEqual:NSNull.null]) {
            value = nil;
        }
        BOOL success = MYMValidateAndSetValue(self, key, value, YES, error);
        if (!success) {
            return nil;
        }
    }
    return self;
}

- (instancetype)init {
    return [super init];
}

+ (void)generateAndCacheStorageBehaviors {
    NSMutableSet *transitoryKeys = [NSMutableSet set];
    NSMutableSet *permanentkeys = [NSMutableSet set];
    
    for (NSString *propertyKey in self.propertyKeys) {
        switch ([self storageBehaviorForPropertyWithKey:propertyKey]) {
            case MYMPropertyStorageNone:
                
                break;
                
            case MYMPropertyStorageTransitory:
                [transitoryKeys addObject:propertyKey];
                break;
            
            case MYMPropertyStoragePermanent:
                [permanentkeys addObject:propertyKey];
                break;
            default:
                break;
        }
    }
    objc_setAssociatedObject(self, MYMModelCachedTransitoryPropertyKeysKey, transitoryKeys, OBJC_ASSOCIATION_COPY);
    objc_setAssociatedObject(self, MYMModelCachedPermanentPropertyKeysKey, permanentkeys, OBJC_ASSOCIATION_COPY);
}


#pragma mark - 反射
+ (void)enumeratePropertiesUsingBlock:(void(^)(objc_property_t property, BOOL *stop))block {
    Class cls = self;
    BOOL stop = NO;
    
    while (!stop && ![cls isEqual:MYMModel.class]) {
        unsigned int count = 0;
        objc_property_t *properties = class_copyPropertyList(cls, &count);
        cls = cls.superclass;
        if (properties == NULL) {
            continue;
        }
        @onExit{
            free(properties);
        };
        
        for (unsigned i = 0; i < count; i++) {
            block(properties[i],&stop);
            if (stop) {
                break;
            }
        }
        
    }
}

+ (NSSet *)permanentPropertyKeys {
    NSSet *permanentPropertyKeys = objc_getAssociatedObject(self, MYMModelCachedPermanentPropertyKeysKey);
    
    if (permanentPropertyKeys == nil) {
        [self generateAndCacheStorageBehaviors];
        permanentPropertyKeys = objc_getAssociatedObject(self, MYMModelCachedPermanentPropertyKeysKey);
    }
    return permanentPropertyKeys;
}

+ (NSSet *)transitoryPropertyKeys {
    NSSet *transitoryPropertyKeys = objc_getAssociatedObject(self, MYMModelCachedTransitoryPropertyKeysKey);
    if (transitoryPropertyKeys == nil) {
        [self generateAndCacheStorageBehaviors];
        transitoryPropertyKeys = objc_getAssociatedObject(self, MYMModelCachedTransitoryPropertyKeysKey);
    }
    return transitoryPropertyKeys;
}

+ (NSSet *)propertyKeys {
    NSSet *cachedKeys = objc_getAssociatedObject(self, MYMModelCachedPropertyKeysKey);
    if (cachedKeys != nil) {
        return cachedKeys;
    }
    
    NSMutableSet *keys = [NSMutableSet set];
    
    [self enumeratePropertiesUsingBlock:^(objc_property_t property, BOOL *stop) {
        NSString *key = @(property_getName(property));
        if ([self storageBehaviorForPropertyWithKey:key] != MYMPropertyStorageNone) {
            [keys addObject:key];
        }
    }];
    
    objc_setAssociatedObject(self, MYMModelCachedPropertyKeysKey, keys, OBJC_ASSOCIATION_COPY);
    return keys;
}

+ (MYMPropertyStorage)storageBehaviorForPropertyWithKey:(NSString *)propertyKey {
    objc_property_t property = class_getProperty(self, propertyKey.UTF8String);
    if (property == NULL) {
        return MYMPropertyStorageNone;
    }
    
    mym_propertyAttributes *attributes = mym_copyPropertyAttributes(property);
    @onExit {
        free(attributes);
    };
    
    BOOL hasGetter = [self instancesRespondToSelector:attributes->getter];
    BOOL hasSetter = [self instancesRespondToSelector:attributes->setter];
    if (!attributes->dynamic && attributes->ivar == NULL && !hasGetter && !hasSetter) {
        return MYMPropertyStorageNone;
    } else if (attributes->readonly && attributes->ivar == NULL){
        if ([self isEqual:MYMModel.class]) {
            return MYMPropertyStorageNone;
        } else {
            // 检查超类，以防子类重新声明属性通过
            return [self.superclass storageBehaviorForPropertyWithKey:propertyKey];
        }
    } else {
        return MYMPropertyStoragePermanent;
    }
}

- (NSDictionary *)dictionaryValue {
    NSSet *keys = [self.class.transitoryPropertyKeys setByAddingObjectsFromSet:self.class.permanentPropertyKeys];
    return [self dictionaryWithValuesForKeys:keys.allObjects];
}


#pragma mark - Merging

- (void)mergeValueForKey:(NSString *)key fromModel:(NSObject<MYMModel> *)model {
    NSParameterAssert(key != nil);
    
    SEL selector = MYMSelectorWithCapitalizedKeyPattern("merge", key, "FromModel");
    
    if (![self respondsToSelector:selector]) {
        if (model != nil) {
            [self setValue:[model valueForKey:key] forKey:key];
        }
        return;
    }
    IMP imp = [self methodForSelector:selector];
    void (*function)(id, SEL, id<MYMModel>) = (__typeof__(function))imp;
    function(self, selector, model);
}

- (void)mergeValuesForKeysFromModel:(id<MYMModel>)model {
    NSSet *propertyKeys = model.class.propertyKeys;
    
    for (NSString *key in self.class.propertyKeys) {
        if (![propertyKeys containsObject:key]) continue;
        
        [self mergeValueForKey:key fromModel:model];
    }
}


#pragma mark - Validation
- (BOOL)validate:(NSError **)error {
    for (NSString *key in self.class.propertyKeys) {
        id value = [self valueForKey:key];
        
        BOOL success = MYMValidateAndSetValue(self, key, value, NO, error);
        if (!success) {
            return NO;
        }
    }
    return YES;
}


#pragma mark - NSCopying
- (instancetype)copyWithZone:(NSZone *)zone {
    MYMModel *copy = [[self.class allocWithZone:zone] init];
    [copy setValuesForKeysWithDictionary:self.dictionaryValue];
    return copy;
}

#pragma mark - NSObject
- (NSString *)description {
    NSDictionary *permanentProperties = [self dictionaryWithValuesForKeys:[[self.class permanentPropertyKeys] allObjects]];
    return [NSString stringWithFormat:@"<%@: %p> %@", self.class, self, permanentProperties];
}

- (NSUInteger)hash {
    NSUInteger value = 0;
    for (NSString *key in self.class.permanentPropertyKeys) {
        value ^= [[self valueForKey:key] hash];
    }
    return value;
}

- (BOOL)isEqual:(MYMModel *)model {
    if (self == model) {
        return YES;
    }
    
    if (![model isMemberOfClass:self.class]) {
        return NO;
    }
    
    for (NSString *key in self.class.permanentPropertyKeys) {
        id selfValue = [self valueForKey:key];
        id modelValue = [model valueForKey:key];
        
        BOOL valuesEqual = ((selfValue == nil && modelValue == nil) || [selfValue isEqual:modelValue]);
        if (!valuesEqual) {
            return NO;
        }
    }
    return YES;
}

@end
