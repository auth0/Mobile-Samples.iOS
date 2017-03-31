#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "A0JWTBuilder.h"
#import "A0RSAKeyExporter.h"
#import "A0TouchID.h"
#import "A0TouchIDAuthentication.h"
#import "NSData+A0JWTSafeBase64.h"
#import "TouchIDAuth.h"

FOUNDATION_EXPORT double TouchIDAuthVersionNumber;
FOUNDATION_EXPORT const unsigned char TouchIDAuthVersionString[];

