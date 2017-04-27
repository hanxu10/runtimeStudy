//
//  NSDictionary+MYMJSONKeyPath.m
//  rumtime
//
//  Created by hanxu on 2017/4/1.
//  Copyright © 2017年 hanxu. All rights reserved.
//

#import "NSDictionary+MYMJSONKeyPath.h"
#import "MYMJSONAdapter.h"
@implementation NSDictionary (MYMJSONKeyPath)
- (id)mym_valueForJSONKeyPath:(NSString *)JSONKeyPath success:(BOOL *)success error:(NSError *__autoreleasing *)error {
    NSArray *components = [JSONKeyPath componentsSeparatedByString:@"."];
    
    id result = self;
    
    for (NSString *component in components) {
        if (result == nil || result == NSNull.null) {
            break;
        }
        
        if (![result isKindOfClass:[NSDictionary class]]) {
            if (error != NULL) {
                NSDictionary *userInfo = @{
                                           NSLocalizedDescriptionKey: NSLocalizedString(@"Invalid JSON dictionary", @""),
                                           NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"JSON key path %1$@ could not resolved because an incompatible JSON dictionary was supplied: \"%2$@\"", @""), JSONKeyPath, self]
                                           };
                
                *error = [NSError errorWithDomain:MYMJSONAdapterErrorDomain code:MYMJSONAdapterErrorInvalidJSONDictionary userInfo:userInfo];
            }
            if (success != NULL) {
                *success = NO;
            }
            return nil;
        }
        result = result[component];
    }
    
    if (success != NULL) {
        *success = YES;
    }
    return result;
}
@end
