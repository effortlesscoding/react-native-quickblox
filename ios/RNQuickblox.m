
#import "RNQuickblox.h"
@import Quickblox;

@implementation RNQuickblox

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(
                  login: (NSInteger) userId
                  password: (NSString*) password
                  resolver:(RCTPromiseResolveBlock) resolve
                  rejecter:(RCTPromiseRejectBlock)reject
                  )
{
    QBUUser *user = [QBUUser user];
    user.ID = (NSUInteger)userId;
    user.password = password;
    
    [[QBChat instance] connectWithUser:user completion:^(NSError * _Nullable error) {
        if (error) {
            NSString *code = [NSString stringWithFormat:@"%ld", error.code];
            reject(code, error.description, error);
        } else {
            resolve(user);
        }
    }];
}

@end
  
