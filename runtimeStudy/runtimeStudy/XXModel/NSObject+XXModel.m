//
//  NSObject+XXModel.m
//  runtimeStudy
//
//  Created by hanxu on 2017/5/2.
//  Copyright © 2017年 hanxu. All rights reserved.
//

#import "NSObject+XXModel.h"
#import "XXClassInfo.h"
#import <objc/message.h>

#define force_inline __inline__ __attribute__((always_inline))

//Foundation库的类
typedef NS_ENUM(NSUInteger, XXEncodingTypeNS) {
    XXEncodingTypeNSUnknown = 0,
    XXEncodingTypeNSString,
    XXEncodingTypeNSMutableString,
    XXEncodingTypeNSValue,
    XXEncodingTypeNSNumber,
    XXEncodingTypeNSDecimalNumber,
    XXEncodingTypeNSData,
    XXEncodingTypeNSMutableData,
    XXEncodingTypeNSDate,
    XXEncodingTypeNSURL,
    XXEncodingTypeNSArray,
    XXEncodingTypeNSMutableArray,
    XXEncodingTypeNSDictionary,
    XXEncodingTypeNSMutableDictionary,
    XXEncodingTypeNSSet,
    XXEncodingTypeNSMutableSet,
};

static force_inline XXEncodingTypeNS XXClassGetTypeNS(Class cls)
{
    if (!cls) {
        return XXEncodingTypeNSUnknown;
    }
    
    if ([cls isSubclassOfClass:[NSMutableString class]]) return XXEncodingTypeNSMutableString;
    if ([cls isSubclassOfClass:[NSString class]]) return XXEncodingTypeNSString;
    if ([cls isSubclassOfClass:[NSDecimalNumber class]]) return XXEncodingTypeNSDecimalNumber;
    if ([cls isSubclassOfClass:[NSNumber class]]) return XXEncodingTypeNSNumber;
    if ([cls isSubclassOfClass:[NSValue class]]) return XXEncodingTypeNSValue;
    if ([cls isSubclassOfClass:[NSMutableData class]]) return XXEncodingTypeNSMutableData;
    if ([cls isSubclassOfClass:[NSData class]]) return XXEncodingTypeNSData;
    if ([cls isSubclassOfClass:[NSDate class]]) return XXEncodingTypeNSDate;
    if ([cls isSubclassOfClass:[NSURL class]]) return XXEncodingTypeNSURL;
    if ([cls isSubclassOfClass:[NSMutableArray class]]) return XXEncodingTypeNSMutableArray;
    if ([cls isSubclassOfClass:[NSArray class]]) return XXEncodingTypeNSArray;
    if ([cls isSubclassOfClass:[NSMutableDictionary class]]) return XXEncodingTypeNSMutableDictionary;
    if ([cls isSubclassOfClass:[NSDictionary class]]) return XXEncodingTypeNSDictionary;
    if ([cls isSubclassOfClass:[NSMutableSet class]]) return XXEncodingTypeNSMutableSet;
    if ([cls isSubclassOfClass:[NSSet class]]) return XXEncodingTypeNSSet;
    return XXEncodingTypeNSUnknown;
}

//判断是否是c Number
static force_inline BOOL XXEncodingTypeIsCNumber(XXEncodingType type)
{
    switch (type & XXEncodingTypeMask) {
        case XXEncodingTypeBool:
        case XXEncodingTypeInt8:
        case XXEncodingTypeUInt8:
        case XXEncodingTypeInt16:
        case XXEncodingTypeUInt16:
        case XXEncodingTypeInt32:
        case XXEncodingTypeUInt32:
        case XXEncodingTypeInt64:
        case XXEncodingTypeUInt64:
        case XXEncodingTypeFloat:
        case XXEncodingTypeDouble:
        case XXEncodingTypeLongDouble:
            return YES;
        
        default:
            return NO;
    }
}


//从'id'解析出number
static force_inline NSNumber *XXNSNumberCreateFromID(__unsafe_unretained id value)
{
    static NSCharacterSet *dot;
    static NSDictionary *dic;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dot = [NSCharacterSet characterSetWithRange:NSMakeRange('.', 1)];
        dic = @{
                @"TRUE" :   @(YES),
                @"True" :   @(YES),
                @"true" :   @(YES),
                @"FALSE" :  @(NO),
                @"False" :  @(NO),
                @"false" :  @(NO),
                @"YES" :    @(YES),
                @"Yes" :    @(YES),
                @"yes" :    @(YES),
                @"NO" :     @(NO),
                @"No" :     @(NO),
                @"no" :     @(NO),
                @"NIL" :    (id)kCFNull,
                @"Nil" :    (id)kCFNull,
                @"nil" :    (id)kCFNull,
                @"NULL" :   (id)kCFNull,
                @"Null" :   (id)kCFNull,
                @"null" :   (id)kCFNull,
                @"(NULL)" : (id)kCFNull,
                @"(Null)" : (id)kCFNull,
                @"(null)" : (id)kCFNull,
                @"<NULL>" : (id)kCFNull,
                @"<Null>" : (id)kCFNull,
                @"<null>" : (id)kCFNull
                
                };
    });
    if (!value || value == (id)kCFNull) {
        return nil;
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        return value;
    }
    if ([value isKindOfClass:[NSString class]]) {
        NSNumber *num = dic[value];
        if (num) {
            if (num == (id)kCFNull) {
                return nil;
            }
            return num;
        }
        if ([(NSString *)value rangeOfCharacterFromSet:dot].location != NSNotFound) {
            const char *cstring = ((NSString *)value).UTF8String;
            if (!cstring) {
                return nil;
            }
            double num = atof(cstring);
            if (isnan(num) || isinf(num)) {
                return nil;
            }
            return @(num);
        } else {
            const char *cstring = ((NSString *)value).UTF8String;
            if (!cstring) {
                return nil;
            }
            return @(atoll(cstring));
        }
    }
    return nil;
}

//把string解析成date
static force_inline NSDate *XXNSDateFromString(__unsafe_unretained NSString *string)
{
    typedef NSDate* (^XXNSDateParseBlock)(NSString *string);
#define kParserNum 34
    static XXNSDateParseBlock blocks[kParserNum + 1] = {0};
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        {
            //2014-01-20 // Google
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter.dateFormat = @"yyyy-MM-dd";
            blocks[10] = ^(NSString *string) {
                return [formatter dateFromString:string];
            };
        }
        
        {
            //2014-01-20 12:24:48
            //2014-01-20T12:24:48    // Google
            //2014-01-20 12:24:48.000
            //2014-01-20T12:24:48.000
            NSDateFormatter *formatter1 = [[NSDateFormatter alloc] init];
            formatter1.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter1.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter1.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss";
            
            NSDateFormatter *formatter2 = [[NSDateFormatter alloc] init];
            formatter2.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter2.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter2.dateFormat = @"yyyy-MM-dd HH:mm:ss";
            
            NSDateFormatter *formatter3 = [[NSDateFormatter alloc] init];
            formatter3.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter3.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter3.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS";
            
            NSDateFormatter *formatter4 = [[NSDateFormatter alloc] init];
            formatter4.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter4.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter4.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";

            blocks[19] = ^(NSString *string){
                if ([string characterAtIndex:10] == 'T') {
                    return [formatter1 dateFromString:string];
                } else {
                    return [formatter2 dateFromString:string];
                }
            };
            
            blocks[23] = ^(NSString *string) {
                if ([string characterAtIndex:10] == 'T') {
                    return [formatter3 dateFromString:string];
                } else {
                    return [formatter4 dateFromString:string];
                }
            };
        }
        
        {
            /*
             2014-01-20T12:24:48Z        // Github, Apple
             2014-01-20T12:24:48+0800    // Facebook
             2014-01-20T12:24:48+12:00   // Google
             2014-01-20T12:24:48.000Z
             2014-01-20T12:24:48.000+0800
             2014-01-20T12:24:48.000+12:00
             */
            NSDateFormatter *formatter = [NSDateFormatter new];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
            
            NSDateFormatter *formatter2 = [NSDateFormatter new];
            formatter2.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter2.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZ";
            
            blocks[20] = ^(NSString *string) { return [formatter dateFromString:string]; };
            blocks[24] = ^(NSString *string) { return [formatter dateFromString:string]?: [formatter2 dateFromString:string]; };
            blocks[25] = ^(NSString *string) { return [formatter dateFromString:string]; };
            blocks[28] = ^(NSString *string) { return [formatter2 dateFromString:string]; };
            blocks[29] = ^(NSString *string) { return [formatter2 dateFromString:string]; };
        }
        
        {
            /*
             Fri Sep 04 00:12:21 +0800 2015 // Weibo, Twitter
             Fri Sep 04 00:12:21.000 +0800 2015
             */
            NSDateFormatter *formatter = [NSDateFormatter new];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter.dateFormat = @"EEE MMM dd HH:mm:ss Z yyyy";
            
            NSDateFormatter *formatter2 = [NSDateFormatter new];
            formatter2.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter2.dateFormat = @"EEE MMM dd HH:mm:ss.SSS Z yyyy";
            
            blocks[30] = ^(NSString *string) { return [formatter dateFromString:string]; };
            blocks[34] = ^(NSString *string) { return [formatter2 dateFromString:string]; };
        }
    });
    if (!string) return nil;
    if (string.length > kParserNum) return nil;
    XXNSDateParseBlock parser = blocks[string.length];
    if (!parser) return nil;
    return parser(string);
#undef kParserNum
}

//获取'NSBlock'class
static force_inline Class XXNSBlockClass()
{
    static Class cls;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        void (^block)(void) = ^{};
        cls = [(NSObject *)block class];
        while (class_getSuperclass(cls) != [NSObject class]) {
            cls = class_getSuperclass(cls);
        }
    });
    return cls;
}


/**
 *  获取ISO date formatter
 *  ISO08601 format 例子:
 *  2010-07-09T16:13:30+12:00
 *  2011-01-11T11:11:11+0000
 *  2011-01-26T19:06:43Z
 */
static force_inline NSDateFormatter *XXISODateFormatter()
{
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
    });
    return formatter;
}

/**
 *  根据key paths获取字典中的value
 *  字典应当是NSDictionary,keypath不能为nil
 */
static force_inline id XXValueForKeyPath(__unsafe_unretained NSDictionary *dic, __unsafe_unretained NSArray *keyPaths)
{
    id value = nil;
    for (NSUInteger i = 0, max = keyPaths.count ; i < max; i++) {
        value = dic[keyPaths[i]];
        if (i + 1 < max) {
            if ([value isKindOfClass:[NSDictionary class]]) {
                dic = value;
            } else {
                return nil;
            }
        }
    }
    return value;
}


static force_inline id XXValueForMultiKeys(__unsafe_unretained NSDictionary *dic, __unsafe_unretained NSArray *multiKeys)
{
    id value = nil;
    for (id key in multiKeys) {
        if ([key isKindOfClass:[NSString class]]) {
            value = dic[key];
            if (value) {
                break;
            }
        } else {
            value = XXValueForKeyPath(dic, (NSArray *)key);
            if (value) {
                break;
            }
        }
    }
    return value;
}

//对象模型中的property info
@interface _XXModelPropertyMeta : NSObject
{
    @package
    NSString *_name;//property的名字
    XXEncodingType _type;//property的type
    XXEncodingTypeNS _nsType;//property的Foundation type
    BOOL _isCNumber;//是否是c number
    Class _cls;//property的类,或者是nil
    Class _genericCls;//容器的通用类,后者是nil
    SEL _getter;//getter,或者为nil(如果实例无法响应)
    SEL _setter;//setter,或者为nil(如果实例无法响应)
    BOOL _isKVCCompatible;//YES,如果可以用kvc访问
    BOOL _isStructAvailableForKeyedArchiver;//YES,如果该结构体可以使用keyed archiver/unarchiver进行编码
    BOOL _hasCustomClassFromDictionary;//类或者通用类实现了+modelCustomClassForDictionary:方法
    
    /*
     property->key:       _mappedToKey:key     _mappedToKeyPath:nil            _mappedToKeyArray:nil
     property->keyPath:   _mappedToKey:keyPath _mappedToKeyPath:keyPath(array) _mappedToKeyArray:nil
     property->keys:      _mappedToKey:keys[0] _mappedToKeyPath:nil/keyPath    _mappedToKeyArray:keys(array)
     */
    NSString *_mappedToKey;//映射到哪个key上
    NSArray *_mappedTokeyPath;//映射到哪个key path.(nil, 如果name不是key path)
    NSArray *_mappedToKeyArray;//key(NSString) 或者 keyPath(NSArrary) 组成的Array.(nil, 如果不映射到多个keys)
    
    XXClassPropertyInfo *_info;//property的info
    _XXModelPropertyMeta *_next;//下一个meta,如果有多个property 映射到同一个key.
    
}

@end


@implementation _XXModelPropertyMeta

+ (instancetype)metaWithClassInfo:(XXClassInfo *)classInfo propertyInfo:(XXClassPropertyInfo *)propertyInfo generic:(Class)generic
{
    ////支持具有协议名称的伪通用类
    if (!generic && propertyInfo.protocols) {
        for (NSString *protocol in propertyInfo.protocols) {
            Class cls = objc_getClass(protocol.UTF8String);
            if (cls) {
                generic = cls;
                break;
            }
        }
    }
    
    _XXModelPropertyMeta *meta = [self new];
    meta->_name = propertyInfo.name;
    meta->_type = propertyInfo.type;
    meta->_info = propertyInfo;
    meta->_genericCls = generic;
    if ((meta->_type & XXEncodingTypeMask) == XXEncodingTypeObject) {
        meta->_nsType = XXClassGetTypeNS(propertyInfo.cls);
    } else {
        meta->_isCNumber = XXEncodingTypeIsCNumber(meta->_type);
    }
    
    if ((meta->_type & XXEncodingTypeMask) == XXEncodingTypeStruct) {
        static NSSet *types = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSMutableSet *set = [NSMutableSet new];
            // 32 bit
            [set addObject:@"{CGSize=ff}"];
            [set addObject:@"{CGPoint=ff}"];
            [set addObject:@"{CGRect={CGPoint=ff}{CGSize=ff}}"];
            [set addObject:@"{CGAffineTransform=ffffff}"];
            [set addObject:@"{UIEdgeInsets=ffff}"];
            [set addObject:@"{UIOffset=ff}"];
            // 64 bit
            [set addObject:@"{CGSize=dd}"];
            [set addObject:@"{CGPoint=dd}"];
            [set addObject:@"{CGRect={CGPoint=dd}{CGSize=dd}}"];
            [set addObject:@"{CGAffineTransform=dddddd}"];
            [set addObject:@"{UIEdgeInsets=dddd}"];
            [set addObject:@"{UIOffset=dd}"];
            types = set;

        });
        if ([types containsObject:propertyInfo.typeEncoding]) {
            meta->_isStructAvailableForKeyedArchiver = YES;
        }
    }
    meta->_cls = propertyInfo.cls;
    
    if (generic) {
        meta->_hasCustomClassFromDictionary = [generic respondsToSelector:@selector(modelCustomClassForDictionary:)];
    } else if (meta->_cls && meta->_nsType == XXEncodingTypeNSUnknown){
        meta->_hasCustomClassFromDictionary = [meta->_cls respondsToSelector:@selector(modelCustomClassForDictionary:)];
    }
    
    if (propertyInfo.getter) {
        if ([classInfo.cls instancesRespondToSelector:propertyInfo.getter]) {
            meta->_getter = propertyInfo.getter;
        }
    }
    if (propertyInfo.setter) {
        if ([classInfo.cls instancesRespondToSelector:propertyInfo.setter]) {
            meta->_setter = propertyInfo.setter;
        }
    }
    
    if (meta->_setter && meta->_getter) {
        //KVC无效的type:
        //long double(貌似oc里没这个吧)
        //pointer (例如:SEL/CoreFoundation 对象)
        switch (meta->_type & XXEncodingTypeMask) {
            case XXEncodingTypeBool:
            case XXEncodingTypeInt8:
            case XXEncodingTypeUInt8:
            case XXEncodingTypeInt16:
            case XXEncodingTypeUInt16:
            case XXEncodingTypeInt32:
            case XXEncodingTypeUInt32:
            case XXEncodingTypeInt64:
            case XXEncodingTypeUInt64:
            case XXEncodingTypeFloat:
            case XXEncodingTypeDouble:
            case XXEncodingTypeObject:
            case XXEncodingTypeClass:
            case XXEncodingTypeBlock:
            case XXEncodingTypeStruct:
            case XXEncodingTypeUnion:
                meta->_isKVCCompatible = YES;
                break;
                
            default: break;

        }
    }
    return meta;
    
}

@end


@interface _XXModelMeta : NSObject
{
    @package
    XXClassInfo *_classInfo;
    NSDictionary *_mapper;//key是映射的key和key path, value是_XXModelPropertyMeta.
    NSArray *_allPropertyMetas;//装的是_XXModelPropertyMeta,该数组包含这个model的所有property meta.
    NSArray *_keyPathPropertyMetas;//
    NSArray *_multiKeysPropertyMetas;//
    NSUInteger _keyMappedCount;//mapped key(和key path)的数量,与_mapper.count相同
    XXEncodingTypeNS _nsType;//模型class type
    
    BOOL _hasCustomWillTransformFromDictionary;
    BOOL _hasCustomTransformFromDictionary;
    BOOL _hasCustomTransformToDictionary;
    BOOL _hasCustomClassFromDictionary;
    
}

@end

@implementation _XXModelMeta

- (instancetype)initWithClass:(Class)cls
{
    XXClassInfo *classInfo = [XXClassInfo classInfoWithClass:cls];
    if (!classInfo) {
        return nil;
    }
    self = [super init];
    
    //获取黑名单
    NSSet *blacklist = nil;
    if ([cls respondsToSelector:@selector(modelPropertyBlacklist)]) {
        NSArray *properties = [(id<XXModel>)cls modelPropertyBlacklist];
        if (properties) {
            blacklist = [NSSet setWithArray:properties];
        }
    }
    
    //获取白名单
    NSSet *whitelist = nil;
    if ([cls respondsToSelector:@selector(modelPropertyWhitelist)]) {
        NSArray *properties = [(id<XXModel>)cls modelPropertyWhitelist];
        if (properties) {
            whitelist = [NSSet setWithArray:properties];
        }
    }
    
    //获取容器属性的generic类
    NSDictionary *genericMapper = nil;
    if ([cls respondsToSelector:@selector(modelContainerPropertyGenericClass)]) {
        genericMapper = [(id<XXModel>)cls modelContainerPropertyGenericClass];
        if (genericMapper) {
            NSMutableDictionary *tmp = [NSMutableDictionary new];
            [genericMapper enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                if (![key isKindOfClass:[NSString class]]) {
                    return;
                }
                //obj是一个Class类型,对class类型取object_getClass,获得meta类
                Class meta = object_getClass(obj);
                if (!meta) {
                    return;
                }
                
                if (class_isMetaClass(meta)) {
                    tmp[key] = obj;
                } else if ([obj isKindOfClass:[NSString class]]) {
                    Class cls = NSClassFromString(obj);
                    if (cls) {
                        tmp[key] = cls;
                    }
                }
            }];
            genericMapper = tmp;
        }
    }
    
    //创建所有的property metas
    NSMutableDictionary *allPropertyMetas = [NSMutableDictionary new];
    XXClassInfo *curClassInfo = classInfo;
    while (curClassInfo && curClassInfo.superCls != nil) {//递归解析super 类,但是忽略根类(NSObjcet/NSProxy)
        for (XXClassPropertyInfo *propertyInfo in curClassInfo.propertyInfos.allValues) {
            if (!propertyInfo.name) {
                continue;
            }
            if (blacklist && [blacklist containsObject:propertyInfo.name]) {
                continue;
            }
            if (whitelist && ![whitelist containsObject:propertyInfo.name]) {
                continue;
            }
            _XXModelPropertyMeta *meta = [_XXModelPropertyMeta metaWithClassInfo:classInfo propertyInfo:propertyInfo generic:genericMapper[propertyInfo.name]];
            if (!meta || !meta->_name) {
                continue;
            }
            if (!meta->_getter || !meta->_setter) {
                continue;
            }
            if (allPropertyMetas[meta->_name]) {
                continue;
            }
            allPropertyMetas[meta->_name] = meta;
        }
        curClassInfo = curClassInfo.superClassInfo;
    }
    if (allPropertyMetas.count) {
        _allPropertyMetas = allPropertyMetas.allValues.copy;
    }
    
    //创建mapper
    NSMutableDictionary *mapper = [NSMutableDictionary new];
    NSMutableArray *keyPathPropertyMetas = [NSMutableArray new];
    NSMutableArray *multiKeysPropertyMetas = [NSMutableArray new];
    
    if ([cls respondsToSelector:@selector(modelCustomPropertyMapper)]) {
        NSDictionary *customMapper = [(id <XXModel>)cls modelCustomPropertyMapper];
        [customMapper enumerateKeysAndObjectsUsingBlock:^(NSString *propertyName, id mappedToKey, BOOL *stop) {
            _XXModelPropertyMeta *propertyMeta = allPropertyMetas[propertyName];
            if (!propertyMeta) {
                return ;
            }
            [allPropertyMetas removeObjectForKey:propertyName];
            
            if ([mappedToKey isKindOfClass:[NSString class]]) {
                if ([(NSString *)mappedToKey length] == 0) {
                    return;
                }
                propertyMeta->_mappedToKey = mappedToKey;
                NSArray *keyPath = [(NSString *)mappedToKey componentsSeparatedByString:@"."];
                for (NSString *onePath in keyPath) {
                    if (onePath.length == 0) {
                        NSMutableArray *tmp = keyPath.mutableCopy;
                        [tmp removeObject:@""];
                        keyPath = tmp;
                        break;
                    }
                }
                if (keyPath.count > 1) {
                    propertyMeta->_mappedTokeyPath = keyPath;
                    [keyPathPropertyMetas addObject:propertyMeta];
                }
                //属性a,b,c都映射到"d"
                //第一次mapped[@"d"] = a;
                //第二次b->next = a; mapped[@"d"] = b;
                //第三次c->next = b; mapped[@"d"] = c;
                //最后c->b->a,mapped["d"] = c;
                //实现多个属性都映射到"d"
                propertyMeta->_next = mapper[mappedToKey] ?: nil;
                mapper[mappedToKey] = propertyMeta;
            } else if ([mappedToKey isKindOfClass:[NSArray class]]) {
                NSMutableArray *mappedToKeyArrary = [NSMutableArray new];
                for (NSString * oneKey in (NSArray *)mappedToKey) {
                    if (![oneKey isKindOfClass:[NSString class]]) {
                        continue;
                    }
                    if (oneKey.length == 0) {
                        continue;
                    }
                    NSArray *keyPath = [oneKey componentsSeparatedByString:@"."];
                    if (keyPath.count > 1) {
                        [mappedToKeyArrary addObject:keyPath];
                    } else {
                        [mappedToKeyArrary addObject:oneKey];
                    }
                    
                    if (!propertyMeta->_mappedToKey) {
                        propertyMeta->_mappedToKey = oneKey;
                        propertyMeta->_mappedTokeyPath = keyPath.count > 1 ? keyPath : nil;
                    }
                }
                if (!propertyMeta->_mappedToKey) {
                    return;
                }
                
                propertyMeta->_mappedToKeyArray = mappedToKeyArrary;
                [multiKeysPropertyMetas addObject:propertyMeta];
                
                propertyMeta->_next = mapper[mappedToKey] ?: nil;
                mapper[mappedToKey] = propertyMeta;
            }
        }];
    }
    
    [allPropertyMetas enumerateKeysAndObjectsUsingBlock:^(NSString *name, _XXModelPropertyMeta *propertyMeta, BOOL *stop) {
        propertyMeta->_mappedToKey = name;
        propertyMeta->_next = mapper[name] ?: nil;
        mapper[name] = propertyMeta;
    }];
    
    if (mapper.count) _mapper = mapper;
    if (keyPathPropertyMetas) _keyPathPropertyMetas = keyPathPropertyMetas;
    if (multiKeysPropertyMetas) _multiKeysPropertyMetas = multiKeysPropertyMetas;
    
    _classInfo = classInfo;
    _keyMappedCount = _allPropertyMetas.count;
    _nsType = XXClassGetTypeNS(cls);
    _hasCustomWillTransformFromDictionary = ([cls instancesRespondToSelector:@selector(modelCustomWillTransformFromDictionary:)]);
    _hasCustomTransformFromDictionary = ([cls instancesRespondToSelector:@selector(modelCustomTransformFromDictionary:)]);
    _hasCustomTransformToDictionary = ([cls instancesRespondToSelector:@selector(modelCustomTransformToDictionary:)]);
    _hasCustomClassFromDictionary = ([cls respondsToSelector:@selector(modelCustomClassForDictionary:)]);
    
    return self;
    

}
/// 返回缓存的model class meta
+ (instancetype)metaWithClass:(Class)cls {
    if (!cls) return nil;
    static CFMutableDictionaryRef cache;
    static dispatch_once_t onceToken;
    static dispatch_semaphore_t lock;
    dispatch_once(&onceToken, ^{
        cache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        lock = dispatch_semaphore_create(1);
    });
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    _XXModelMeta *meta = CFDictionaryGetValue(cache, (__bridge const void *)(cls));
    dispatch_semaphore_signal(lock);
    if (!meta || meta->_classInfo.needUpdate) {
        meta = [[_XXModelMeta alloc] initWithClass:cls];
        if (meta) {
            dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
            CFDictionarySetValue(cache, (__bridge const void *)(cls), (__bridge const void *)(meta));
            dispatch_semaphore_signal(lock);
        }
    }
    return meta;
}

@end


/**
  从属性获取number
  @discussion 在此函数返回之前，调用者应当对参数进行强引用。
  @param  model 不应该是nil。
  @param   meta 不应该是nil，meta.isCNumber应该是YES，meta.getter不应该是nil。
  @return   一个数字对象，如果失败则为nil。
  */
static force_inline NSNumber *ModelCreateNumberFromProperty(__unsafe_unretained id model, __unsafe_unretained _XXModelPropertyMeta *meta)
{
    switch (meta -> _type & XXEncodingTypeMask) {
        case XXEncodingTypeBool:{
            
            return @(((bool (*)(id, SEL))objc_msgSend)(model, meta->_getter));
        }
        case XXEncodingTypeInt8: {
            return @(((int8_t (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter));
        }
        case XXEncodingTypeUInt8: {
            return @(((uint8_t (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter));
        }
        case XXEncodingTypeInt16: {
            return @(((int16_t (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter));
        }
        case XXEncodingTypeUInt16: {
            return @(((uint16_t (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter));
        }
        case XXEncodingTypeInt32: {
            return @(((int32_t (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter));
        }
        case XXEncodingTypeUInt32: {
            return @(((uint32_t (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter));
        }
        case XXEncodingTypeInt64: {
            return @(((int64_t (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter));
        }
        case XXEncodingTypeUInt64: {
            return @(((uint64_t (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter));
        }
        case XXEncodingTypeFloat: {
            float num = ((float (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter);
            if (isnan(num) || isinf(num)) return nil;
            return @(num);
        }
        case XXEncodingTypeDouble: {
            double num = ((double (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter);
            if (isnan(num) || isinf(num)) return nil;
            return @(num);
        }
        case XXEncodingTypeLongDouble: {
            double num = ((long double (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter);
            if (isnan(num) || isinf(num)) return nil;
            return @(num);
        }
        default: return nil;

    }
}


/**
  将number设置到property
  @discussion   在此函数返回之前，来电者应该坚持参考参数。
  @param  model 不应该是ni。
  @param num 可以为nil。
  @param meta 不应该是nil，meta.isCNumber应该是YES，meta.setter不应该是nil。
  */
static force_inline void ModelSetNumberToProperty(__unsafe_unretained id model, __unsafe_unretained NSNumber *num, __unsafe_unretained _XXModelPropertyMeta *meta)
{
    switch (meta->_type & XXEncodingTypeMask) {
        case XXEncodingTypeBool: {
            ((void (*)(id, SEL, bool))(void *) objc_msgSend)((id)model, meta->_setter, num.boolValue);
        } break;
        case XXEncodingTypeInt8: {
            ((void (*)(id, SEL, int8_t))(void *) objc_msgSend)((id)model, meta->_setter, (int8_t)num.charValue);
        } break;
        case XXEncodingTypeUInt8: {
            ((void (*)(id, SEL, uint8_t))(void *) objc_msgSend)((id)model, meta->_setter, (uint8_t)num.unsignedCharValue);
        } break;
        case XXEncodingTypeInt16: {
            ((void (*)(id, SEL, int16_t))(void *) objc_msgSend)((id)model, meta->_setter, (int16_t)num.shortValue);
        } break;
        case XXEncodingTypeUInt16: {
            ((void (*)(id, SEL, uint16_t))(void *) objc_msgSend)((id)model, meta->_setter, (uint16_t)num.unsignedShortValue);
        } break;
        case XXEncodingTypeInt32: {
            ((void (*)(id, SEL, int32_t))(void *) objc_msgSend)((id)model, meta->_setter, (int32_t)num.intValue);
        }
        case XXEncodingTypeUInt32: {
            ((void (*)(id, SEL, uint32_t))(void *) objc_msgSend)((id)model, meta->_setter, (uint32_t)num.unsignedIntValue);
        } break;
        case XXEncodingTypeInt64: {
            if ([num isKindOfClass:[NSDecimalNumber class]]) {
                ((void (*)(id, SEL, int64_t))(void *) objc_msgSend)((id)model, meta->_setter, (int64_t)num.stringValue.longLongValue);
            } else {
                ((void (*)(id, SEL, uint64_t))(void *) objc_msgSend)((id)model, meta->_setter, (uint64_t)num.longLongValue);
            }
        } break;
        case XXEncodingTypeUInt64: {
            if ([num isKindOfClass:[NSDecimalNumber class]]) {
                ((void (*)(id, SEL, int64_t))(void *) objc_msgSend)((id)model, meta->_setter, (int64_t)num.stringValue.longLongValue);
            } else {
                ((void (*)(id, SEL, uint64_t))(void *) objc_msgSend)((id)model, meta->_setter, (uint64_t)num.unsignedLongLongValue);
            }
        } break;
        case XXEncodingTypeFloat: {
            float f = num.floatValue;
            if (isnan(f) || isinf(f)) f = 0;
            ((void (*)(id, SEL, float))(void *) objc_msgSend)((id)model, meta->_setter, f);
        } break;
        case XXEncodingTypeDouble: {
            double d = num.doubleValue;
            if (isnan(d) || isinf(d)) d = 0;
            ((void (*)(id, SEL, double))(void *) objc_msgSend)((id)model, meta->_setter, d);
        } break;
        case XXEncodingTypeLongDouble: {
            long double d = num.doubleValue;
            if (isnan(d) || isinf(d)) d = 0;
            ((void (*)(id, SEL, long double))(void *) objc_msgSend)((id)model, meta->_setter, (long double)d);
        }
        default: break;
    }
}
 






























@implementation NSObject (XXModel)



@end
