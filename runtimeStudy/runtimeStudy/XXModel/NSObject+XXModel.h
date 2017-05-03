//
//  NSObject+XXModel.h
//  runtimeStudy
//
//  Created by hanxu on 2017/5/2.
//  Copyright © 2017年 hanxu. All rights reserved.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN



/**
 Provide some data-model method:
 
 * Convert json to any object, or convert any object to json.
 * Set object properties with a key-value dictionary (like KVC).
 * Implementations of `NSCoding`, `NSCopying`, `-hash` and `-isEqual:`.
 
 See `YYModel` protocol for custom methods.
 
 
 Sample Code:
 
 ********************** json convertor *********************
 @interface YYAuthor : NSObject
 @property (nonatomic, strong) NSString *name;
 @property (nonatomic, assign) NSDate *birthday;
 @end
 @implementation YYAuthor
 @end
 
 @interface YYBook : NSObject
 @property (nonatomic, copy) NSString *name;
 @property (nonatomic, assign) NSUInteger pages;
 @property (nonatomic, strong) YYAuthor *author;
 @end
 @implementation YYBook
 @end
 
 int main() {
 // create model from json
 YYBook *book = [YYBook yy_modelWithJSON:@"{\"name\": \"Harry Potter\", \"pages\": 256, \"author\": {\"name\": \"J.K.Rowling\", \"birthday\": \"1965-07-31\" }}"];
 
 // convert model to json
 NSString *json = [book yy_modelToJSONString];
 // {"author":{"name":"J.K.Rowling","birthday":"1965-07-31T00:00:00+0000"},"name":"Harry Potter","pages":256}
 }
 
 ********************** Coding/Copying/hash/equal *********************
 @interface YYShadow :NSObject <NSCoding, NSCopying>
 @property (nonatomic, copy) NSString *name;
 @property (nonatomic, assign) CGSize size;
 @end
 
 @implementation YYShadow
 - (void)encodeWithCoder:(NSCoder *)aCoder { [self yy_modelEncodeWithCoder:aCoder]; }
 - (id)initWithCoder:(NSCoder *)aDecoder { self = [super init]; return [self yy_modelInitWithCoder:aDecoder]; }
 - (id)copyWithZone:(NSZone *)zone { return [self yy_modelCopy]; }
 - (NSUInteger)hash { return [self yy_modelHash]; }
 - (BOOL)isEqual:(id)object { return [self yy_modelIsEqual:object]; }
 @end
 
 */

@interface NSObject (XXModel)

/**
 * 根据json创建一个对象.该方法线程安全
 *
 * @param json 可以是NSDictionary, NSString, NSData.
 *
 */
+ (instancetype)xx_modelWithJSON:(id)json;

/**
 * 从字典创建对象.
 * @discussion dictionary中的key与属性的名字映射,value被设为属性的值.
 *              如果value的type与property的type不匹配,将尝试按照下面的规则进行转换:
 *              NSString 或 NSNumber ----> c number,例如BOOL,int,long,float,NSUInteger...
 *              NSString             ----> NSDate,用"yyyy-MM-dd'T'HH:mm:ssZ", "yyyy-MM-dd HH:mm:ss" or 
 *                                          "yyyy-MM-dd"进行解析
 *
 *              NSString             ----> NSURL
 *              NSValue              ----> struct 或者 union.例如,CGRect,CGSize
 *              NSString             ----> SEL, Class
 */
+ (instancetype)xx_modelWithDictionary:(NSDictionary *)dictionary;


/**
  使用json对象设置接收者的属性。
 
  @discussion json中的任何无效数据都将被忽略。
 
  @param json “NSDictionary”，“NSString”或“NSData”映射到接收者的属性。
 
  @return 是否成功
 */
- (BOOL)xx_modelSetWithJSON:(id)json;

- (BOOL)xx_modelSetWithDictionary:(NSDictionary *)dic;

/**
  从接收者生成一个json对象。
 
  @return 以“NSDictionary”或“NSArray”形式返回一个json，如果发生错误，则为nil。
  有关详细信息，请参阅[NSJSONSerialization isValidJSONObject]。
 
  @discussion 任何无效的属性都被忽略。
  如果reciver是“NSArray”，“NSDictionary”或“NSSet”，它只把转换
  内部对象转为json。
 */
- (id)xx_modelToJSONObject;


/**
  从接收者生成一个json字符串的data。
 
  @return 一个json字符串的data，如果发生错误，则为nil。
 
  @discussion 任何无效的属性都被忽略。
                如果reciver是“NSArray”，“NSDictionary”或“NSSet”，它也会转换
                内部对象到json字符串。
 */
- (NSData *)xx_modelToJSONData;


/**
  从接收者生成一个json字符串。
 
  @return 一个json字符串，如果发生错误，则为nil。
 
  @discussion 任何无效的属性都被忽略。
                如果reciver是“NSArray”，“NSDictionary”或“NSSet”，它也会转换
                内部对象到json字符串。
 */
- (NSString *)xx_modelToJSONString;


/**
  复制具有接收者属性的实例。
 
  @return 复制的实例，如果发生错误，则为nil。
 */
- (id)xx_modelCopy;

/**
  将接收器的属性编码为一个coder。
 
  @param aCoder 一个archiver对象。
 */
- (void)xx_modelEncodeWithCoder:(NSCoder *)aCoder;


/**
  从解码器解码接收机的属性。
  */
- (id)xx_modelInitWithCoder:(NSCoder *)aDecoder;


- (NSUInteger)xx_modelHash;


- (BOOL)xx_modelIsEqual:(id)model;


- (NSString *)yy_modelDescription;
@end




@interface NSArray (XXModel)

/**
  从json数组创建并返回一个数组。
  这种方法是线程安全的。
 
  @param cls 数组中的实例类。
  @param json 一个`NSArray`，`NSString`或`NSData`的json数组。
               示例：[{“name”，“Mary”}，{name：“Joe”}]
  */
+ (NSArray *)xx_modelArrayWithClass:(Class)cls json:(id)json;

@end

@interface NSDictionary (XXModel)
/**
  从json创建并返回一个字典。
  这种方法是线程安全的。
 
  @param cls 字典中value的实例类。
  @param json “NSDictionary”，“NSString”或“NSData”的json字典。
               示例：{“user1”：{“name”，“Mary”}，“user2”：{name：“Joe”}}
 
  @return 一个字典，如果发生错误，则为nil。
  */
+ (NSDictionary *)xx_modelDictionaryWithClass:(Class)cls json:(id)json;
@end






/**
  如果默认的模型转换不适合您的模型类，请实现该协议中的一个或
  多个方法,来改变默认的键值转换过程。
  没有必要将'<YYModel>'添加到你的类头。
  */
@protocol XXModel <NSObject>
@optional
/**
 自定义属性映射
 
 @discussion 如果JSON与模型中的property名字不匹配,实现这个方法,来返回附加的映射关系.
 
 例如:
 
 json:
 {
 "n":"Harry Pottery",
 "p": 256,
 "ext" : {
 "desc" : "A book written by J.K.Rowling."
 },
 "ID" : 100010
 }
 
 模型:
 @interface YYBook : NSObject
 @property NSString *name;
 @property NSInteger page;
 @property NSString *desc;
 @property NSString *bookID;
 @end
 
 @implementation YYBook
 + (NSDictionary *)modelCustomPropertyMapper {
    return @{@"name"  : @"n",
            @"page"  : @"p",
            @"desc"  : @"ext.desc",
            @"bookID": @[@"id", @"ID", @"book_id"]
    };
 }
 @end
 
 @return A custom mapper for properties.
 */
+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper;



/**
 容器属性的通用类映射器。
 
 @discussion 如果该属性是个容器对象,例如NSArray/NSSet/NSDictionary,实现该方法,返回一个 property->class 的映射, 告知哪种对象要加入到集合中.
 
 例如:
 @class YYShadow, YYBorder, YYAttachment;
 
 @interface YYAttributes
 @property NSString *name;
 @property NSArray *shadows;
 @property NSSet *borders;
 @property NSDictionary *attachments;
 @end
 
 @implementation YYAttributes
 + (NSDictionary *)modelContainerPropertyGenericClass {
 return @{@"shadows" : [YYShadow class],
 @"borders" : YYBorder.class,
 @"attachments" : @"YYAttachment" };
 }
 @end
 
 @return A class mapper.
 */
+ (nullable NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass;


/**
 If you need to create instances of different classes during json->object transform,
 use the method to choose custom class based on dictionary data.
 
 @discussion If the model implements this method, it will be called to determine resulting class
 during `+modelWithJSON:`, `+modelWithDictionary:`, conveting object of properties of parent objects
 (both singular and containers via `+modelContainerPropertyGenericClass`).
 
 如果您需要在json->对象变换期间创建不同类的实例，
 使用该方法根据字典数据选择自定义类。
  
 @discussion 如果模型实现了这个方法，它将在`+ modelWithJSON：`，`+ modelWithDictionary：`中被调用来确定结果类
   ，父对象的属性的获取对象
   （通过`+ modelContainerPropertyGenericClass`单个和容器）。
 
 
 例如:
 @class YYCircle, YYRectangle, YYLine;
 
 @implementation YYShape
 
 + (Class)modelCustomClassForDictionary:(NSDictionary*)dictionary {
    if (dictionary[@"radius"] != nil) {
        return [YYCircle class];
    } else if (dictionary[@"width"] != nil) {
        return [YYRectangle class];
    } else if (dictionary[@"y2"] != nil) {
        return [YYLine class];
    } else {
        return [self class];
    }
 }
 
 @end
 
 @param dictionary The json/kv dictionary.
 
 @return Class to create from this dictionary, `nil` to use current class.
 
 */
+ (Class)modelCustomClassForDictionary:(NSDictionary *)dictionary;

/**
    黑名单中的所有属性将在模型转换过程中被忽略。
    返回nil以忽略此功能。
 */
+ (nullable NSArray<NSString *> *)modelPropertyBlacklist;


/**
    如果属性不在白名单中，则在模型转换过程中将被忽略。
    返回nil以忽略此功能。
 */
+ (nullable NSArray<NSString *> *)modelPropertyWhitelist;



/**
  这个方法的行为类似于` - （BOOL）modelCustomTransformFromDictionary：（NSDictionary *）dic;`，
  但是在模型转换之前被调用。
 
  @discussion 如果模型实现了这个方法，它将在下面这些方法之前被调用:`+ modelWithJSON：`，`+ modelWithDictionary：`，`-modelSetWithJSON：`和`-modelSetWithDictionary：`。
  如果此方法返回nil，则转换过程将忽略此模型。
 
  @param dic json/kv字典。
 
  @return 返回修改后的字典，或nil忽略此模型。
  */
- (NSDictionary *)modelCustomWillTransformFromDictionary:(NSDictionary *)dic;



/**
 If the default json-to-model transform does not fit to your model object, implement
 this method to do additional process. You can also use this method to validate the
 model's properties.
 
 @discussion If the model implements this method, it will be called at the end of
 `+modelWithJSON:`, `+modelWithDictionary:`, `-modelSetWithJSON:` and `-modelSetWithDictionary:`.
 If this method returns NO, the transform process will ignore this model.
 
 @param dic  The json/kv dictionary.
 
 @return Returns YES if the model is valid, or NO to ignore this model.
 */
- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic;

/**
 If the default model-to-json transform does not fit to your model class, implement
 this method to do additional process. You can also use this method to validate the
 json dictionary.
 
 @discussion If the model implements this method, it will be called at the end of
 `-modelToJSONObject` and `-modelToJSONString`.
 If this method returns NO, the transform process will ignore this json dictionary.
 
 @param dic  The json dictionary.
 
 @return Returns YES if the model is valid, or NO to ignore this model.
 */
- (BOOL)modelCustomTransformToDictionary:(NSMutableDictionary *)dic;
@end













NS_ASSUME_NONNULL_END
