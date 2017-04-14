//
//  NSString+Formatting.m
//  RNQuickblox
//
//  Created by Anh Dao on 4/14/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import "NSString+Formatting.h"

@implementation NSString (Formatting)

- (NSNumber *) numberValue
{
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    return [f numberFromString:self];
}

@end
