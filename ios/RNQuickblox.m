
#import <React/RCTEventDispatcher.h>
#import "RNQuickblox.h"
#import "QBError+ErrorsFormatting.h"
#import "NSError+Initializers.h"
#import "QBChatMessage+Formatting.h"
#import "NSString+Formatting.h"
@import UserNotifications;

NSString *const QBChatMessageSent = @"QBChatMessageSent";
NSString *const QBChatMessageReceived = @"QBChatMessageReceived";
NSString *const QBChatConnectionError = @"QBChatConnectionError";
NSString *const QBChatConnected = @"QBChatConnected";

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
                  login: (NSString *) userId
                  username: (NSString*) username
                  password: (NSString*) password
                  resolver:(RCTPromiseResolveBlock) resolve
                  rejecter:(RCTPromiseRejectBlock)reject
                  )
{
    QBUUser *user = [QBUUser user];
    user.ID  = [userId integerValue];
    user.login = username;
    user.password = password;
    // If I just use QBRequest login, then the delegates (didReceiveMessage, etc.) will not work
    [[QBChat instance] connectWithUser:user completion:^(NSError * _Nullable error) {
        if (error) {
            BOOL canIgnore = error.code == -1000 && [error.userInfo[@"NSLocalizedRecoverySuggestion"] isEqualToString:@"You are already connected to chat."];
            if (!canIgnore) {
                reject(
                       [NSString stringWithFormat: @"%ld", error.code],
                       error.description,
                       error
                       );
                return;
            } else {
                [_bridge.eventDispatcher sendDeviceEventWithName:QBChatConnected body: @{}];
            }
        }
        // OK, I don't understand something... Why do we need to login twice?
        [QBRequest logInWithUserLogin:username password:password successBlock:^(QBResponse * _Nonnull response, QBUUser * _Nullable user) {
            resolve(@{
                      @"id": user.ID ? [NSString stringWithFormat: @"%lu", user.ID] : @"",
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
                       [NSString stringWithFormat:@"%ld", (long)code],
                       reason,
                       [NSError errorWithCode:code reason:reason]
                       );
            }
        }];
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
        NSDictionary *opponentsDialogsMapping = mappings[1];
        resolve(opponentsDialogsMapping);
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
                   [NSString stringWithFormat:@"%ld", (long)code],
                   reason,
                   [NSError errorWithCode:code reason:reason]
                   );
        }
    }];
}

RCT_EXPORT_METHOD(
                  createPrivateDialog:(NSString *) opponentQuickbloxId
                  resolver:(RCTPromiseResolveBlock) resolve
                  rejecter:(RCTPromiseRejectBlock)reject
                  )
{
    QBChatDialog *chatDialog = [[QBChatDialog alloc] initWithDialogID:nil type:QBChatDialogTypePrivate];
    chatDialog.name = @"Private chat";
    chatDialog.occupantIDs = @[[opponentQuickbloxId numberValue]];
    [QBRequest createDialog:chatDialog successBlock:^(QBResponse * _Nonnull response, QBChatDialog * _Nullable createdDialog) {
        NSDictionary *data = @{
                               @"dialogID": createdDialog.ID,
                               @"opponentID": opponentQuickbloxId
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
                   [NSString stringWithFormat:@"%ld", (long)code],
                   reason,
                   [NSError errorWithCode:code reason:reason]
                   );
        }
    }];
}

RCT_EXPORT_METHOD(
                  sendTextMessage:(NSString*)dialogId
                  text: (NSString*)text
                  resolver:(RCTPromiseResolveBlock) resolve
                  rejecter:(RCTPromiseRejectBlock)reject
                  )
{
    QBChatDialog *dialog = [dialogs objectForKey:dialogId];
    if (!dialog) {
        return;
    }
    QBChatMessage *message = [QBChatMessage markableMessage];
    NSMutableDictionary *customParams = [NSMutableDictionary new];
    customParams[@"save_to_history"] = @"1";
    message.customParameters = customParams;
    [message setText:text ? text : @""];
    // TODO: Set a couple other parameters ...
    // TODO: Loop through all dialogs that you found ...
    [dialog sendMessage:message completionBlock:^(NSError * _Nullable error) {
        if (error) {
            NSString *code = [NSString stringWithFormat:@"%ld", error.code];
            reject(code, error.description, error);
        } else {
            resolve([message dictionaryValue]);
        }
    }];
}

RCT_EXPORT_METHOD(
                  sendVideoChat: (NSString*)dialogId
                  video: (NSString*)videoUrl
                  thumbnail:(NSString*)thumbnailUrl
                  text:(NSString*)additionalMessage
                  resolver:(RCTPromiseResolveBlock) resolve
                  rejecter:(RCTPromiseRejectBlock)reject
                  )
{
    QBChatDialog *dialog = [dialogs objectForKey:dialogId];
    if (!dialog) {
        NSError *error = [NSError errorWithCode:99 reason:@"No dialog found"];
        reject([NSString stringWithFormat:@"%ld",(long)error.code], error.description, error);
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
            resolve([message dictionaryValue]);
        }
    }];
}

RCT_EXPORT_METHOD(
                  loadChatMessages:(NSString*)dialogId
                  resolver:(RCTPromiseResolveBlock) resolve
                  rejecter:(RCTPromiseRejectBlock)reject
                  )
{
    [QBRequest messagesWithDialogID:dialogId successBlock:^(QBResponse * _Nonnull response, NSArray<QBChatMessage *> * _Nullable messages) {
        // Convert everything to an array of dictionary values.
        NSArray *data = [self dictionaryMappingsFrom:messages];
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
                   [NSString stringWithFormat:@"%ld", (long)code],
                   reason,
                   [NSError errorWithCode:code reason:reason]
                   );
        }
    }];
}

#pragma mark Converters

- (NSArray *) dictionaryMappingsFrom: (NSArray<QBChatMessage *> *) chatMessages
{
    NSMutableArray *convertedValues = [[NSMutableArray alloc] init];
    for (QBChatMessage *chatMessage in chatMessages)
    {
        [convertedValues addObject:[chatMessage dictionaryValue]];
    }
    return convertedValues;
}

- (NSArray *) dictionaryMappingsFrom: (NSArray<QBChatDialog *> *) dialogObjects withUser: (NSString *) userIdParam
{
    // TODO: Handle it more properly
    NSInteger userId = [userIdParam integerValue];
    NSMutableDictionary<NSString *, NSString*>  *opponentsDialogIdsMappings = [[NSMutableDictionary alloc] init];
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
            [opponentsDialogIdsMappings setObject: dialog.ID forKey:[opponentId stringValue]];
        }
    }
    return @[
             dialogIdMapping,
             opponentsDialogIdsMappings
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
                            @"opponentID": [NSNumber numberWithInteger: userID]
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


- (void)chatRoomDidReceiveMessage:(QBChatMessage *)message fromDialogID:(NSString *)dialogID
{
    [_bridge.eventDispatcher sendDeviceEventWithName:QBChatMessageReceived body: [message dictionaryValue]];
}

/**
 *  Called whenever new system message was received from QBChat.
 *
 *  @param message Message that was received from Chat
 *
 *  @note Will be called only on recipient device
 */
- (void)chatDidReceiveSystemMessage:(QBChatMessage *)message
{
    NSLog(@"Wonderful");
}

/**
 *  Called whenever QBChat connection error happened.
 *
 *  @param error XMPPStream Error
 */
- (void)chatDidFailWithStreamError:(nullable NSError *)error
{
    NSLog(@"Wonderful");
}

/**
 *  Called whenever QBChat did connect.
 */
- (void)chatDidConnect
{
    [_bridge.eventDispatcher sendDeviceEventWithName:QBChatConnected body: @{}];
}

/**
 *  Called whenever connection process did not finish successfully.
 *
 *  @param error connection error
 */
- (void)chatDidNotConnectWithError:(nullable NSError *)error
{
    [_bridge.eventDispatcher sendDeviceEventWithName:QBChatConnectionError body: @{}];
}

/**
 *  Called whenever QBChat did accidentally disconnect.
 */
- (void)chatDidAccidentallyDisconnect
{
    NSLog(@"Wonderful");
}

/**
 *  Called after successful connection to chat after disconnect.
 */
- (void)chatDidReconnect
{
    NSLog(@"Wonderful");
}
@end

