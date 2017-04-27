//
//  PersonModel.h
//  rumtime
//
//  Created by hanxu on 2017/4/5.
//  Copyright © 2017年 hanxu. All rights reserved.
//

#import "MYM.h"

@interface PersonModel : MYMModel <MYMJSONSerializing>
@property (nonatomic, assign) NSInteger start;
@property (nonatomic, assign) NSInteger end;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *name;
@end
