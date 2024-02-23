//
//  SendbirdNotificationHelper.h
//
//  Created by Airen Kang on 2024/02/20.
//  Copyright © 2024 Sendbird. All rights reserved.
//

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0 || \
    __MAC_OS_X_VERSION_MAX_ALLOWED >= __MAC_10_14
#import <UserNotifications/UserNotifications.h>
#endif

typedef void (^ErrorHandler)(NSError * _Nullable error);

NS_ASSUME_NONNULL_BEGIN

@interface SendbirdNotificationHelper : NSObject

+ (void)markPushNotificationAsDelivered:(NSDictionary *)remoteNotificationPayload
                     completionHandler:(nullable ErrorHandler)completionHandler;

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;

@end

NS_ASSUME_NONNULL_END
