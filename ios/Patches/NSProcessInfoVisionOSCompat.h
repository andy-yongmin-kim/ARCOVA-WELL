// Forward-declares isiOSAppOnVision so device_info_plus 12.x/13.x compiles
// against the iOS 18.x SDK, where the selector is not yet declared.
// Injected via OTHER_CFLAGS in the Podfile post_install hook.
#ifndef NSProcessInfo_VisionOSCompat_h
#define NSProcessInfo_VisionOSCompat_h
#ifdef __OBJC__
#import <Foundation/Foundation.h>
@interface NSProcessInfo (VisionOSCompat)
@property (readonly) BOOL isiOSAppOnVision API_AVAILABLE(ios(26.1));
@end
#endif
#endif
