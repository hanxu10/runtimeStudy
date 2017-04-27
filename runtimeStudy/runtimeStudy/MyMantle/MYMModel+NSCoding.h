//
//  MYMModel+NSCoding.h
//  rumtime
//
//  Created by hanxu on 2017/3/11.
//  Copyright © 2017年 hanxu. All rights reserved.
//

#import "MYMModel.h"

///定义MTLModel属性键应如何编码到归档中。
typedef enum : NSUInteger {
    //该property不会被编码
    MYMModelEncodingBehaviorExcluded = 0,
    //该property总会被编码
    MYMModelEncodingBehaviorUnconditional,
    //只有在无条件地在别处编码时，对象才应该被编码。 这只应该用于对象属性。
    MYMModelEncodingBehaviorConditional,
} MYMModelEncodingBehavior;

//实现默认的归档和解档行为
@interface MYMModel (NSCoding)<NSCoding>

//从归档来初始化一个Model
//这将解码归档对象的原始+ modelVersion，然后为接收者的每个+propertyKeys调用-decodeValueForKey：withCoder：modelVersion：。
- (instancetype)initWithCoder:(NSCoder *)aDecoder;

///使用给定的编码器存档接收器。
///这将编码receiver的+ modelVersion，并根据+ encodingBehaviorsByPropertyKey中指定的行为来编码receiver的属性。
- (void)encodeWithCoder:(NSCoder *)aCoder;


///确定类的+ propertyKeys如何编码到归档中。
///这个字典的值应该是boxed的MTLModelEncodingBehavior值。
///
///字典中不存在的任何键都将从归档中排除。
///
///覆盖此方法的子类应该将它们的值与`super`的值组合。
///
///返回将接收者的+ propertyKeys映射到默认编码行为的字典。 如果属性是具有`weak`语义的对象，默认行为是MTLModelEncodingBehaviorConditional; 否则，默认值为MTLModelEncodingBehaviorUnconditional。
+ (NSDictionary *)encodingBehaviorsByPropertyKey;




///确定在使用<NSSecureCoding>时允许为每个接收器的属性解码的类。 这个字典的值应该是Class对象的NSArrays。
///
///如果任何可编码键（由+ encodingBehaviorsByPropertyKey确定）不存在于字典中，则在安全编码或解码期间将抛出异常。
///
///覆盖此方法的子类应该将它们的值与`super`的值组合。
///
///返回一个字典，将接收器的可编码键（由+ encodingBehaviorsByPropertyKey确定）映射到默认允许的类，基于每个属性声明的类型。 如果不能确定可编码属性的类型（例如，它被声明为“id”），则它将从字典中被省略，并且子类必须提供有效值以防止在编码/解码期间抛出异常。
+ (NSDictionary *)allowedSecureCodingClassesByPropertyKey;




///解码来自归档的给定属性键的值。
///默认情况下，此方法在接收器上查找`-decode <Key> WithCoder：modelVersion：`方法，如果找到，则调用它。
///如果没有实现自定义方法，并且`coder'不需要安全编码，` - [NSCoder decodeObjectForKey：]`将使用给定的`key`来调用。
///如果没有实现自定义方法，并且“coder”需要安全编码，则将使用+ allowedSecureCodingClassesByPropertyKey和给定的“key”的信息调用[NSCoder decodeObjectOfClasses：forKey：]。接收器必须符合<NSSecureCoding>，才能正常工作。
/// key - 解码值的属性键。这个参数不能为nil。
/// coder - 表示正在解码的归档的NSCoder。这个参数不能为nil。
/// modelVersion - 已编码的原始模型对象的版本。
///返回解码和boxed值，如果键不存在则返回nil。
- (id)decodeValueForKey:(NSString *)key withCoder:(NSCoder *)coder modelVersion:(NSUInteger)modelVersion;




///此MTLModel子类的版本。
///此版本号保存在归档中，以便以后的模型更改可以向后兼容旧版本。
///当对模型进行破坏更改时，子类应该覆盖此方法以返回更高的版本号。
///返回0。
+ (NSUInteger)modelVersion;

@end


@interface MYMModel (OldArchiveSupport)
///将存档的外部表示转换为适合传递给-initWithDictionary：的字典。
/// externalRepresentation - 接收器的解码外部表示。
/// fromVersion - 外部表示形式编码时的模型版本。
///默认返回nil，表示转换失败。
+ (NSDictionary *)dictionaryValueFromArchivedExternalRepresentation:(NSDictionary *)externalRepresentation version:(NSUInteger)fromVersion;

@end
































