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
    NSArray<NSString *> *values = [self.reasons allValues];
    NSMutableString *allReasons = [[NSMutableString alloc] init];
    for (NSString * reason in values) {
        [allReasons appendString: [reason capitalizedString]];
        [allReasons appendString: @". "];
    }
    return allReasons;
}
@end
