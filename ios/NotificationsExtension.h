
#ifdef RCT_NEW_ARCH_ENABLED
#import "RNNotificationsExtensionSpec.h"

@interface NotificationsExtension : NSObject <NativeNotificationsExtensionSpec>
#else
#import <React/RCTBridgeModule.h>

@interface NotificationsExtension : NSObject <RCTBridgeModule>
#endif

@end
