//
//  NSDictionary+MYMManipulationAdditions.h
//  rumtime
//
//  Created by hanxu on 2017/4/1.
//  Copyright © 2017年 hanxu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (MYMManipulationAdditions)
///将给定字典的键和值合并到接收器中。 如果接收器和“字典”都有一个给定的键，则使用“dictionary”中的值。
///
///返回一个新的字典，其中包含与“dictionary”相结合的接收者条目。
- (NSDictionary *)mym_dictionaryByAddingEntriesFromDictionary:(NSDictionary *)dictionary;


///创建一个新的字典，其中包含从接收器中删除的给定键的所有条目。
- (NSDictionary *)mym_dictionaryByRemovingValuesForKeys:(NSArray *)keys;
@end
