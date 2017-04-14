//
//  QBChatMessage+Formatting.m
//  RNQuickblox
//
//  Created by Anh Dao on 4/7/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import "QBChatMessage+Formatting.h"

@implementation QBChatMessage (Formatting)

- (NSDictionary *) dictionaryValue
{
    NSMutableDictionary *finalDictionary = [[NSMutableDictionary alloc] init];
    [finalDictionary setObject:self.text ? self.text : @"" forKey:@"text"];
    [finalDictionary setObject:self.ID ? self.ID : @"" forKey:@"ID"];
    [finalDictionary setObject:[NSString stringWithFormat:@"%lu", self.senderID] forKey: @"senderID"];
    [finalDictionary setObject:[NSString stringWithFormat:@"%lu", self.recipientID] forKey: @"recipientID"];
    [finalDictionary setObject:self.dialogID forKey:@"dialogID"];
    if (self.customParameters) {
        [finalDictionary addEntriesFromDictionary:self.customParameters];
    }
    return finalDictionary;
}
@end
