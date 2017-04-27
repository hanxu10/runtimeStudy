//
//  ViewController.m
//  rumtime
//
//  Created by hanxu on 2017/3/8.
//  Copyright © 2017年 hanxu. All rights reserved.
//

#import "ViewController.h"
#import "MYM.h"
#import "PersonModel.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSDictionary *dict = @{
                           @"start": @0000,
                           @"end": @9999,
                           @"user_id": @"用户id",
                           @"name": @"用户名称",
                           };
    
}

//- (void)logAllPropertys:(Class)class{
//    Class tempClass = class;
//    while (![tempClass isEqual:NSObject.class] ) {
//        unsigned int count = 0;
//        objc_property_t *propertys = class_copyPropertyList(tempClass, &count);
//        tempClass = tempClass.superclass;
//        @try {
//            for (int i = 0; i < count; i++) {
//                objc_property_t property = propertys[i];
//                NSLog(@"%@",[NSString stringWithUTF8String:property_getName(property)]);
//            }
//        } @catch (NSException *exception) {
//            
//        } @finally {
//            free(propertys);
//        }
//
//    }
//}


@end
