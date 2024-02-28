#import "AppDelegate.h"
#import "SendbirdNotificationHelper.h"

#import <React/RCTBundleURLProvider.h>
#import <UserNotifications/UserNotifications.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  self.moduleName = @"NotificationsExtensionExample";
  self.initialProps = @{};

  // NOTE: set app group to share device token
  [SendbirdNotificationHelper setAppGroup:@"group.sample.chat.react-native"];
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge
{
  return [self getBundleURL];
}

- (NSURL *)getBundleURL
{
#if DEBUG
  return [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index"];
#else
  return [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
#endif
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
  // NOTE: pass device token
  [SendbirdNotificationHelper didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

@end
