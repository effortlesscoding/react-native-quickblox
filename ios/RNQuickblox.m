
#import <React/RCTEventDispatcher.h>
#import "RNQuickblox.h"
#import "QBError+ErrorsFormatting.h"
#import "NSError+Initializers.h"
#import "QBChatMessage+Formatting.h"
@import UserNotifications;

NSString *const QBDialogsLoaded = @"QBDialogsLoaded";
NSString *const QBChatMessageSent = @"QBChatMessageSent";
NSString *const QBChatMessageReceived = @"QBChatMessageReceived";

@implementation RNQuickblox {
    @private
    NSMutableDictionary<NSString *, QBChatDialog *> *dialogs;
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE()

@synthesize bridge = _bridge;

RCT_EXPORT_METHOD(
                  initialize:(RCTPromiseResolveBlock) resolve
                  rejecter:(RCTPromiseRejectBlock)reject
                  )
{
    [[QBChat instance] removeAllDelegates];
    [[QBChat instance] addDelegate: self];
    resolve(@"");
}

RCT_EXPORT_METHOD(
                  login: (NSString *) login
                  password: (NSString*) password
                  resolver:(RCTPromiseResolveBlock) resolve
                  rejecter:(RCTPromiseRejectBlock)reject
                  )
{
    [QBRequest logInWithUserLogin:login password:password successBlock:^(QBResponse * _Nonnull response, QBUUser * _Nullable user) {
        resolve(@{
                  @"id": [NSString stringWithFormat:@"%ld", user.ID],
                  @"login": user.login ? user.login : @"",
                  @"password": user.password ? user.password : @""
                  });
    } errorBlock:^(QBResponse * _Nonnull response) {
        if (response.error) {
            reject(
                   [response.error errorCode],
                   [response.error errorsSentence],
                   response.error.error
                   );
        } else {
            NSInteger code = 99;
            NSString *reason = @"Quickblox response does not have an error";
            reject(
                   [NSString stringWithFormat:@"%ld", code],
                   reason,
                   [NSError errorWithCode:code reason:reason]
                   );
        }
    }];
}

RCT_EXPORT_METHOD(
                  loadDialogs: (NSString *) userId
                  resolver:(RCTPromiseResolveBlock) resolve
                  rejecter:(RCTPromiseRejectBlock)reject
                  )
{
    [QBRequest dialogsWithSuccessBlock:^(QBResponse * _Nonnull response, NSArray<QBChatDialog *> * _Nullable dialogObjects, NSSet<NSNumber *> * _Nullable dialogsUsersIDs) {
        NSArray *mappings = [self dictionaryMappingsFrom: dialogObjects withUser:userId];
        dialogs = mappings[0];
        NSDictionary *data = @{
                               @"usersDialogs": mappings[1]
                               };
        resolve(data);
    } errorBlock:^(QBResponse * _Nonnull response) {
        if (response.error) {
            reject(
                   [response.error errorCode],
                   [response.error errorsSentence],
                   response.error.error
                   );
        } else {
            NSInteger code = 99;
            NSString *reason = @"Quickblox response does not have an error";
            reject(
                   [NSString stringWithFormat:@"%ld", code],
                   reason,
                   [NSError errorWithCode:code reason:reason]
                   );
        }
    }];
}

RCT_EXPORT_METHOD(
                  createPrivateDialog: (NSNumber *) myQuickbloxId
                  opponent:(NSNumber *) opponentQuickbloxId
                  resolver:(RCTPromiseResolveBlock) resolve
                  rejecter:(RCTPromiseRejectBlock)reject
                  )
{
    QBChatDialog *chatDialog = [[QBChatDialog alloc] initWithDialogID:nil type:QBChatDialogTypePrivate];
    chatDialog.name = @"Private chat";
    chatDialog.occupantIDs = @[myQuickbloxId, opponentQuickbloxId];
    [QBRequest createDialog:chatDialog successBlock:^(QBResponse * _Nonnull response, QBChatDialog * _Nullable createdDialog) {
        NSDictionary *data = @{
                               @"dialogId": createdDialog.ID
                               };
        resolve(data);
    } errorBlock:^(QBResponse * _Nonnull response) {
        if (response.error) {
            reject(
                   [response.error errorCode],
                   [response.error errorsSentence],
                   response.error.error
                   );
        } else {
            NSInteger code = 99;
            NSString *reason = @"Quickblox response does not have an error";
            reject(
                   [NSString stringWithFormat:@"%ld", code],
                   reason,
                   [NSError errorWithCode:code reason:reason]
                   );
        }
    }];
}

RCT_EXPORT_METHOD(
                  sendTextChat:(NSString*)text
                  dialogId: (NSString*)dialogId
                  resolver:(RCTPromiseResolveBlock) resolve
                  rejecter:(RCTPromiseRejectBlock)reject
                  )
{
    QBChatDialog *dialog = [dialogs objectForKey:dialogId];
    if (!dialog) {
        return;
    }
    QBChatMessage *message = [QBChatMessage message];
    NSMutableDictionary *customParams = [NSMutableDictionary new];
    customParams[@"save_to_history"] = @"1";
    message.customParameters = customParams;
    [message setText:text];
    // TODO: Set a couple other parameters ...
    // TODO: Loop through all dialogs that you found ...
    [dialog sendMessage:message completionBlock:^(NSError * _Nullable error) {
        if (error) {
            NSString *code = [NSString stringWithFormat:@"%ld", error.code];
            reject(code, error.description, error);
        } else {
            resolve(@"Successfuly sent");
        }
    }];
}

RCT_EXPORT_METHOD(
                  sendVideoChat:(NSString*)videoUrl
                  thumbnail:(NSString*)thumbnailUrl
                  text:(NSString*)additionalMessage
                  dialogId: (NSString*)dialogId
                  resolver:(RCTPromiseResolveBlock) resolve
                  rejecter:(RCTPromiseRejectBlock)reject
                  )
{
    QBChatDialog *dialog = [dialogs objectForKey:dialogId];
    if (!dialog) {
        return;
    }
    QBChatMessage *message = [QBChatMessage message];
    NSMutableDictionary *customParams = [NSMutableDictionary new];
    customParams[@"save_to_history"] = @"1";
    customParams[@"message_type"] = @"v";
    customParams[@"thumbnail_url"] = thumbnailUrl;
    customParams[@"video_url"] = videoUrl;
    message.customParameters = customParams;
    [message setText:additionalMessage];
    // TODO: Set a couple other parameters ...
    // TODO: Loop through all dialogs that you found ...
    [dialog sendMessage:message completionBlock:^(NSError * _Nullable error) {
        if (error) {
            NSString *code = [NSString stringWithFormat:@"%ld", error.code];
            reject(code, error.description, error);
        } else {
            resolve(@"Successfuly sent");
        }
    }];
}

- (NSArray *) dictionaryMappingsFrom: (NSArray<QBChatDialog *> *) dialogObjects withUser: (NSString *) userIdParam
{
    // TODO: Handle it more properly
    NSInteger userId = [userIdParam integerValue];
    NSMutableDictionary<NSString *, NSString*>  *usersDialogIdsMappings = [[NSMutableDictionary alloc] init];
    NSMutableDictionary<NSString *, QBChatDialog *> *dialogIdMapping = [[NSMutableDictionary alloc] init];
    for (QBChatDialog *dialog in dialogObjects) {
        NSNumber *opponentId = [NSNumber numberWithInteger:-1];
        for (NSNumber *occupantId in dialog.occupantIDs) {
            if (occupantId.integerValue != userId) {
                opponentId = occupantId;
            }
        }
        if (opponentId.integerValue > -1) {
            [dialogIdMapping setObject: dialog forKey: dialog.ID];
            [usersDialogIdsMappings setObject: dialog.ID forKey:[opponentId stringValue]];
        }
    }
    return @[
             dialogIdMapping,
             usersDialogIdsMappings
             ];
}

#pragma mark Quickblox Notifications setup

- (void)setBridge:(RCTBridge *)bridge
{
    _bridge = bridge;
}

#pragma mark QBChatDelegate

- (void) dialogsLoaded
{
    
}

/**
 *  Called whenever message was delivered to user.
 *
 *  @param messageID Message identifier
 *  @param dialogID  Dialog identifier
 *  @param userID   User identifier
 */
- (void)chatDidDeliverMessageWithID:(NSString *)messageID dialogID:(NSString *)dialogID toUserID:(NSUInteger)userID
{
    NSDictionary *params = @{
                            @"messageID": messageID,
                            @"dialogID": dialogID,
                            @"userID": [NSNumber numberWithInteger: userID]
                            };
    [_bridge.eventDispatcher sendDeviceEventWithName:QBChatMessageSent body:params];
}

/**
 *  Called whenever new private message was received from QBChat.
 *
 *  @param message Message received from Chat
 *
 *  @note Will be called only on recipient device
 */
- (void)chatDidReceiveMessage:(QBChatMessage *)message
{
    [_bridge.eventDispatcher sendDeviceEventWithName:QBChatMessageReceived body:[message dictionaryValue]];
}
@end

