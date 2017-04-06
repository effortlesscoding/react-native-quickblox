//
//  NSError+Initializers.h
//  RNQuickblox
//
//  Created by Anh Dao on 4/7/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSError (Initializers)

+ (NSError *) errorWithCode: (NSInteger) code reason: (NSString*) reason;
@end
