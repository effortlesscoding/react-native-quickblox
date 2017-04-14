//
//  NSObject+QBResponse_ErrorsFormatting.m
//  RNQuickblox
//
//  Created by Anh Dao on 4/7/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import "QBError+ErrorsFormatting.h"

@implementation QBError (ErrorsFormatting)

- (NSString *) errorCode
{
    return [NSString stringWithFormat:@"%ld", self.error.code];
}

- (NSString *) errorsSentence
{
    NSMutableString *allReasons = [[NSMutableString alloc] initWithString: @"Failed a quickblox request."];
    for (NSString * key in self.reasons) {
        id reason = self.reasons[key];
        if ([reason isKindOfClass: [NSString class]]) {
            [allReasons appendString: [reason capitalizedString]];
            [allReasons appendString: @". "];
        } else if ([reason isKindOfClass:[NSDictionary class]]) {
            for (NSString * reasonKey in reason) {
                id reasonInner = reason[reasonKey];
                if ([reasonInner isKindOfClass: [NSString class]]) {
                    [allReasons appendString: [reasonInner capitalizedString]];
                    [allReasons appendString: @". "];
                } else if ([reasonInner isKindOfClass:[NSArray class]]) {
                    NSArray *reasonsInner = reasonInner;
                    if ([reasonsInner count] > 0) {
                        if ([reasonsInner[0] isKindOfClass:[NSString class]]) {
                            [allReasons appendString: [reasonsInner[0] capitalizedString]];
                            [allReasons appendString: @". "];
                        }
                    }
                }
            }
        }
    }
    return allReasons;
}
@end
