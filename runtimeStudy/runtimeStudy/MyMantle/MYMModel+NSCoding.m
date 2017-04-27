//
//  MYMModel+NSCoding.m
//  rumtime
//
//  Created by hanxu on 2017/3/11.
//  Copyright © 2017年 hanxu. All rights reserved.
//

#import "MYMModel+NSCoding.h"
#import "MYMReflection.h"
#import "MYMEXTRuntimeExtensions.h"
#import "MYMEXTScope.h"
//用于在archives中存储归档实例的modelVersion。
static NSString * const MYMModelVersionKey = @"MYMModelVersion";

//用于缓存在+ allowedSecureCodingClassesByPropertyKey中执行的反射。
static void *MYMModelCachedAllowedClassesKey = &MYMModelCachedAllowedClassesKey;

//返回给定的NSCoder是否需要安全编码。
static BOOL coderRequiresSecureCoding(NSCoder *coder) {
    SEL requiresSecureCodingSelector = @selector(requiresSecureCoding);
    if (![coder respondsToSelector:requiresSecureCodingSelector]) {
        //只在该方法实现的时候调用（例如，仅仅在OS X 10.8+ 和 iOS 6+）
        return NO;
    }
    BOOL (*requiresSecureCodingIMP)(NSCoder *, SEL) = (__typeof__(requiresSecureCodingIMP))[coder methodForSelector:requiresSecureCodingSelector];
    if (requiresSecureCodingIMP == NULL) {
        return NO;
    }
    return requiresSecureCodingIMP(coder, requiresSecureCodingSelector);
}

//返回所有给定类的可编码属性键（不会从归档中排除的属性键）。
static NSSet *encodablePropertyKeysForClass(Class modelClass) {
    return [[modelClass encodingBehaviorsByPropertyKey] keysOfEntriesPassingTest:^BOOL(NSString *propertyKey, NSNumber *behavior, BOOL *stop) {
        return behavior.unsignedIntegerValue != MYMModelEncodingBehaviorExcluded;
    }];
}

//验证所有指定类的可编码属性键是否存在于+ allowedSecureCodingClassesByPropertyKey中，如果没有，则抛出异常。
static void verifyAllowedClassesByPropertyKey(Class modelClass) {
    NSDictionary *allowedClasses = [modelClass allowedSecureCodingClassesByPropertyKey];
    NSMutableSet * specifiedPropertyKeys = [[NSMutableSet alloc] initWithArray:allowedClasses.allKeys];
    [specifiedPropertyKeys minusSet:encodablePropertyKeysForClass(modelClass)];
    
    if (specifiedPropertyKeys.count > 0) {
        [NSException raise:NSInvalidArgumentException format:@"Cannot encode %@ securely, because keys are missing from +allowedSecureCodingClassesByPropertyKey: %@", modelClass, specifiedPropertyKeys];
    }
}

@implementation MYMModel (NSCoding)
+ (NSUInteger)modelVersion {
    return 0;
}

#pragma mark - Encoding Behaviors
+ (NSDictionary *)encodingBehaviorsByPropertyKey {
    NSSet *propertyKeys = self.propertyKeys;
    NSMutableDictionary *behaviors = [[NSMutableDictionary alloc] initWithCapacity:propertyKeys.count];
    
    for (NSString *key in propertyKeys) {
        objc_property_t property = class_getProperty(self, key.UTF8String);
        NSAssert(property != NULL, @"Could not find property \"%@\" on %@", key, self);
        mym_propertyAttributes *attributes = mym_copyPropertyAttributes(property);
        
        @onExit {
            free(attributes);
        };
        
        MYMModelEncodingBehavior behavior = (attributes->weak ? MYMModelEncodingBehaviorConditional : MYMModelEncodingBehaviorUnconditional);
        behaviors[key] = @(behavior);
    }
    return behaviors;
}

+ (NSDictionary *)allowedSecureCodingClassesByPropertyKey {
    NSDictionary *cachedClasses = objc_getAssociatedObject(self, MYMModelCachedAllowedClassesKey);
    if (cachedClasses != nil) {
        return cachedClasses;
    }
    
    NSSet *propertyKeys = [self.encodingBehaviorsByPropertyKey keysOfEntriesPassingTest:^BOOL(NSString *propertyKey, NSNumber *behavior, BOOL *stop) {
        return behavior.unsignedIntegerValue != MYMModelEncodingBehaviorExcluded;
    }];
    
    NSMutableDictionary *allowedClasses = [[NSMutableDictionary alloc] initWithCapacity:propertyKeys.count];
    for (NSString *key in propertyKeys) {
        objc_property_t property = class_getProperty(self, key.UTF8String);
        NSAssert(property != NULL, @"Could not find property \"%@\" on %@", key, self);
        
        mym_propertyAttributes *attributes = mym_copyPropertyAttributes(property);
        @onExit{
            free(attributes);
        };
        
        ////如果属性不是对象或类类型，则假设它是一个将被框入NSValue的原语。
        if (attributes->type[0] != '@' && attributes->type[0] != '#') {
            allowedClasses[key] = @[NSValue.class];
            continue;
        }
        
        ////如果该类未知，则从字典中忽略此属性。
        if (attributes->objectClass != nil) {
            allowedClasses[key] = @[attributes->objectClass];
        }
    }
    
    objc_setAssociatedObject(self, MYMModelCachedAllowedClassesKey, allowedClasses, OBJC_ASSOCIATION_COPY);
    return allowedClasses;
}

- (id)decodeValueForKey:(NSString *)key withCoder:(NSCoder *)coder modelVersion:(NSUInteger)modelVersion {
    NSParameterAssert(key != nil);
    NSParameterAssert(coder != nil);
    
    SEL selector = MYMSelectorWithCapitalizedKeyPattern("decode", key, "WithCoder:modelVersion:");
    if ([self respondsToSelector:selector]) {
        IMP imp = [self methodForSelector:selector];
        id (*function)(id, SEL, NSCoder *, NSUInteger) = (__typeof__(function))imp;
        id result = function(self, selector, coder, modelVersion);
        return result;
    }
    @try {
        if (coderRequiresSecureCoding(coder)) {
            NSArray *allowedClasses = self.class.allowedSecureCodingClassesByPropertyKey[key];
            NSAssert(allowedClasses != nil, @"No allowed classes specified for securely decoding key \"%@\" on %@", key, self.class);
            
            return [coder decodeObjectOfClasses:[NSSet setWithArray:allowedClasses] forKey:key];
        } else {
            return [coder decodeObjectForKey:key];
        }
        
    } @catch (NSException *ex) {
        NSLog(@"*** Caught exception decoding value for key \"%@\" on class %@: %@", key, self.class, ex);
        @throw ex;

    }
    
}


- (instancetype)initWithCoder:(NSCoder *)coder {
    BOOL requiresSecureCoding = coderRequiresSecureCoding(coder);
    NSNumber *version = nil;
    if (requiresSecureCoding) {
        version = [coder decodeObjectOfClass:NSNumber.class forKey:MYMModelVersionKey];
    } else {
        version = [coder decodeObjectForKey:MYMModelVersionKey];
    }
    
    if (version == nil) {
        NSLog(@"Warning: decoding an archive of %@ without a version, assuming 0", self.class);
    } else if (version.unsignedIntegerValue > self.class.modelVersion) {
        // Don't try to decode newer versions.
        return nil;
    }
    
    if (requiresSecureCoding) {
        verifyAllowedClassesByPropertyKey(self.class);
    } else {
        // Handle the old archive format.
        NSDictionary *externalRepresentation = [coder decodeObjectForKey:@"externalRepresentation"];
        if (externalRepresentation != nil) {
            NSAssert([self.class methodForSelector:@selector(dictionaryValueFromArchivedExternalRepresentation:version:)] != [MYMModel methodForSelector:@selector(dictionaryValueFromArchivedExternalRepresentation:version:)], @"Decoded an old archive of %@ that contains an externalRepresentation, but +dictionaryValueFromArchivedExternalRepresentation:version: is not overridden to handle it", self.class);
            
            NSDictionary *dictionaryValue = [self.class dictionaryValueFromArchivedExternalRepresentation:externalRepresentation version:version.unsignedIntegerValue];
            if (dictionaryValue == nil) return nil;
            
            NSError *error = nil;
            self = [self initWithDictionary:dictionaryValue error:&error];
            if (self == nil) NSLog(@"*** Could not decode old %@ archive: %@", self.class, error);
            
            return self;
        }
    }
    
    NSSet *propertyKeys = self.class.propertyKeys;
    NSMutableDictionary *dictionaryValue = [[NSMutableDictionary alloc] initWithCapacity:propertyKeys.count];
    
    for (NSString *key in propertyKeys) {
        id value = [self decodeValueForKey:key withCoder:coder modelVersion:version.unsignedIntegerValue];
        if (value == nil) continue;
        
        dictionaryValue[key] = value;
    }
    
    NSError *error = nil;
    self = [self initWithDictionary:dictionaryValue error:&error];
    if (self == nil) NSLog(@"*** Could not unarchive %@: %@", self.class, error);
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    if (coderRequiresSecureCoding(coder)) verifyAllowedClassesByPropertyKey(self.class);
    
    [coder encodeObject:@(self.class.modelVersion) forKey:MYMModelVersionKey];
    
    NSDictionary *encodingBehaviors = self.class.encodingBehaviorsByPropertyKey;
    [self.dictionaryValue enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
        @try {
            // Skip nil values.
            if ([value isEqual:NSNull.null]) return;
            
            switch ([encodingBehaviors[key] unsignedIntegerValue]) {
                    // This will also match a nil behavior.
                case MYMModelEncodingBehaviorExcluded:
                    break;
                    
                case MYMModelEncodingBehaviorUnconditional:
                    [coder encodeObject:value forKey:key];
                    break;
                    
                case MYMModelEncodingBehaviorConditional:
                    [coder encodeConditionalObject:value forKey:key];
                    break;
                    
                default:
                    NSAssert(NO, @"Unrecognized encoding behavior %@ on class %@ for key \"%@\"", self.class, encodingBehaviors[key], key);
            }
        } @catch (NSException *ex) {
            NSLog(@"*** Caught exception encoding value for key \"%@\" on class %@: %@", key, self.class, ex);
            @throw ex;
        }
    }];
}



    
#pragma mark NSSecureCoding

+ (BOOL)supportsSecureCoding {
    // Disable secure coding support by default, so subclasses are forced to
    // opt-in by conforming to the protocol and overriding this method.
    //
    // We only implement this method because XPC complains if a subclass tries
    // to implement it but does not override -initWithCoder:. See
    // https://github.com/github/Mantle/issues/74.
    return NO;
}
@end

@implementation MYMModel (OldArchiveSupport)
+ (NSDictionary *)dictionaryValueFromArchivedExternalRepresentation:(NSDictionary *)externalRepresentation version:(NSUInteger)fromVersion {
    return nil;
}
@end
