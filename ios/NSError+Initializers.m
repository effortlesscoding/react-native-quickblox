//
//  NSError+Initializers.m
//  RNQuickblox
//
//  Created by Anh Dao on 4/7/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import "NSError+Initializers.h"

@implementation NSError (Initializers)

+ (NSError *) errorWithCode: (NSInteger) code reason: (NSString*) reason
{
    
    NSDictionary *errorDictionary = @{
                                      NSLocalizedDescriptionKey : reason,
                                      NSUnderlyingErrorKey : [NSNull null],
                                      NSFilePathErrorKey : @""
                                    };
    NSError *error = [[NSError alloc] initWithDomain:NSPOSIXErrorDomain
                                                code:code userInfo:errorDictionary];
    return error;
}
@end
