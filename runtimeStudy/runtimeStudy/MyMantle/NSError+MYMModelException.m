//
//  NSError+MYMModelException.m
//  rumtime
//
//  Created by hanxu on 2017/4/1.
//  Copyright © 2017年 hanxu. All rights reserved.
//

#import "NSError+MYMModelException.h"
#import "MYMModel.h"


// The domain for errors originating from MTLModel.
static NSString * const MYMModelErrorDomain = @"MYMModelErrorDomain";

// An exception was thrown and caught.
static const NSInteger MYMModelErrorExceptionThrown = 1;

// Associated with the NSException that was caught.
static NSString * const MYMModelThrownExceptionErrorKey = @"MYMModelThrownException";



@implementation NSError (MYMModelException)
+ (instancetype)mym_modelErrorWithException:(NSException *)exception {
    NSParameterAssert(exception != nil);
    
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey: exception.description,
                               NSLocalizedFailureReasonErrorKey: exception.reason,
                               MYMModelThrownExceptionErrorKey: exception
                               };
    return [NSError errorWithDomain:MYMModelErrorDomain code:MYMModelErrorExceptionThrown userInfo:userInfo];

}
@end
