//
//  NSDictionary+MYMJSONKeyPath.h
//  rumtime
//
//  Created by hanxu on 2017/4/1.
//  Copyright © 2017年 hanxu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (MYMJSONKeyPath)

- (id)mym_valueForJSONKeyPath:(NSString *)JSONKeyPath success:(BOOL *)success error:(NSError **)error;

@end
