//
//  MYMReflection.h
//  rumtime
//
//  Created by hanxu on 2017/3/11.
//  Copyright © 2017年 hanxu. All rights reserved.
//

#import <Foundation/Foundation.h>

//从一个key和常量字符串创建一个selector

//key       要插入到生成的选择器中的键。 这个键应该在其自然的情况下。
//suffix    作为选择器一部分附加到键的字符串。

//返回选择器，如果输入字符串无法形成有效的选择器，则返回NULL。
SEL MYMSelectorWithKeyPattern(NSString *key, const char *suffix) __attribute__((pure, nonnull(1,2)));



//从一个key和常量前缀和后缀字符串创建一个selector

/// prefix - 作为选择器一部分预先加到键的字符串。
/// key - 要插入到生成的选择器中的键。 这个键应该是在自然的情况下，并将插入时其第一个字母大写。
/// suffix - 作为选择器一部分附加到键的字符串。
///
///返回选择器，如果输入字符串无法形成有效的选择器，则返回NULL。
SEL MYMSelectorWithCapitalizedKeyPattern(const char *prefix, NSString *key, const char *suffix) __attribute__((pure, nonnull(1,2,3)));

















