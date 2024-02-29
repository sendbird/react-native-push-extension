//
//  SendbirdNotificationHelper.m
//
//  Created by Airen Kang on 2024/02/20.
//  Copyright © 2024 Sendbird. All rights reserved.
//

#import "SendbirdNotificationHelper.h"

@implementation SendbirdNotificationHelper

static NSString* SBNExtensionGroup = @"group.name";
static NSString*const SBNDeviceTokenKey = @"sendbird.device-token";
static NSString*const SBNExtensionVersion = @"0.0.1";

// Mark: - exports
//
// #import "SendbirdNotificationHelper.h"
//
// [SendbirdNotificationHelper markPushNotificationAsDelivered:payload];
// [SendbirdNotificationHelper didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
// [SendbirdNotificationHelper setAppGroup:suiteName];
+ (void)markPushNotificationAsDelivered:(nonnull NSDictionary *)remoteNotificationPayload
                      completionHandler:(nullable ErrorHandler)completionHandler {

    NSDictionary *data = @{ NSLocalizedDescriptionKey: @"Malformed data" };
    NSError *error = [NSError errorWithDomain:@"SendbirdNotificationHelper" code:1 userInfo:data];

    NSDictionary *sendbird = remoteNotificationPayload[@"sendbird"];
    if (![sendbird isKindOfClass:[NSDictionary class]]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionHandler) completionHandler(error);
        });
        return;
    }
    
    NSString *deviceToken = [self getSavedDeviceToken];
    NSString *appId = [sendbird[@"app_id"] uppercaseString];
    NSString *pushTrackingId = sendbird[@"push_tracking_id"];
    NSDictionary *session = sendbird[@"session_key"];
    NSString *sessionKey = session[@"key"];
    NSArray *sessionTopics = session[@"topics"];

    if (![appId isKindOfClass:[NSString class]] || ![pushTrackingId isKindOfClass:[NSString class]] ||
        ![sessionKey isKindOfClass:[NSString class]] || ![sessionTopics isKindOfClass:[NSArray class]]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionHandler) {
                completionHandler(error);
            }
        });
        return;
    }

    if (![sessionTopics containsObject:@"push_acknowledgement"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionHandler) {
                completionHandler(error);
            }
        });
        return;
    }
    
    [self sendPushDeliveryWithSessionKey:sessionKey
                                   appId:appId
                             deviceToken:deviceToken
                          pushTrackingId:pushTrackingId
                       completionHandler:completionHandler];
}


+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *tokenString = [self stringFromDeviceToken:deviceToken];
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:SBNExtensionGroup];
    [defaults setObject:tokenString forKey:SBNDeviceTokenKey];
    [defaults synchronize];
}

+ (void)setAppGroup:(NSString *)suiteName {
    SBNExtensionGroup = suiteName;
}

// Mark: - internal
+ (void)sendPushDeliveryWithSessionKey:(NSString *)sessionKey
                                 appId:(NSString *)appId
                           deviceToken:(nullable NSString *)deviceToken
                        pushTrackingId:(nullable NSString *)pushTrackingId
                     completionHandler:(nullable ErrorHandler)completionHandler {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api-%@.sendbird.com/v3/sdk/push_delivery", appId]];
    NSData *body = [NSJSONSerialization dataWithJSONObject:@{@"device_token": deviceToken, @"push_tracking_id": pushTrackingId} options:kNilOptions error:nil];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:body];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:sessionKey forHTTPHeaderField:@"Session-Key"];
    [request setValue:[NSString stringWithFormat:@"device_os_platform=ios&os_version=%@&extension_sdk_info=notifications/react-native/%@", [[UIDevice currentDevice] systemVersion], SBNExtensionVersion] forHTTPHeaderField:@"SB-SDK-User-Agent"];
    [request setValue:[NSString stringWithFormat:@"%lld", (long long)([[NSDate date] timeIntervalSince1970] * 1000)] forHTTPHeaderField:@"Request-Sent-Timestamp"];

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error && completionHandler) {
            completionHandler(error);
            return;
        }
        
        NSDictionary *body = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        
        BOOL isError = [body[@"error"] boolValue];
        NSString *message = body[@"message"];
        NSInteger code = [body[@"code"] integerValue];
        if (isError && completionHandler) {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: message };
            NSError *responseError = [NSError errorWithDomain:@"SendbirdNotificationHelper" code:code userInfo:userInfo];
            completionHandler(responseError);
            return;
        }

        [[self pushAckedCache] addObject:pushTrackingId];
        if (completionHandler) completionHandler(nil);
    }];
    [task resume];
}

+ (NSMutableSet *)pushAckedCache {
    static NSMutableSet *cacheSet = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cacheSet = [NSMutableSet set];
    });
    return cacheSet;
}

+ (NSString *)stringFromDeviceToken:(NSData *)deviceToken {
    const char *data = [deviceToken bytes];
    NSMutableString *tokenString = [NSMutableString string];
    
    for (NSUInteger i = 0; i < [deviceToken length]; i++) {
        [tokenString appendFormat:@"%02.2hhX", data[i]];
    }
    
    return [tokenString copy];
}

+ (NSString *)getSavedDeviceToken {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:SBNExtensionGroup];
    NSString *savedToken = [defaults objectForKey:SBNDeviceTokenKey];
    
    if (savedToken) {
        return savedToken;
    } else {
        return @"";
    }
}


@end
