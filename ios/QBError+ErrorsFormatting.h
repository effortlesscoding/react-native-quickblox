//
//  NSObject+QBResponse_ErrorsFormatting.h
//  RNQuickblox
//
//  Created by Anh Dao on 4/7/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

@import Quickblox;

@interface QBError (ErrorsFormatting)

- (NSString *) errorCode;
- (NSString *) errorsSentence;
@end
