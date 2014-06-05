//
//  FPMCredentialStore.h
//  FuturePhone
//
//  Created by alden on 6/1/14.
//  Copyright (c) 2014 futurephone. All rights reserved.
//

#import <Foundation/Foundation.h>

#define FPM_PHONE_NUMBER_KEY (@"phone_number")
#define FPM_SESSION_KEY_KEY (@"session_key")

@interface FPMCredentialStore : NSObject

+ (void)saveSessionKey:(NSString*)sessionKey forPhoneNumber:(NSString*)phoneNumber;
+ (NSDictionary*)savedSessionKeyAndPhoneNumber;

+ (void)savePhoneNumber:(NSString*)phoneNumber;
+ (NSString*)savedPhoneNumber;

+ (void)clearCredentials;

@end
