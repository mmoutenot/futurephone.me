//
//  FPMCredentialStore.m
//  FuturePhone
//
//  Created by alden on 6/1/14.
//  Copyright (c) 2014 futurephone. All rights reserved.
//

#import <Security/Security.h>

#import "FPMCredentialStore.h"
#import "KeychainItemWrapper.h"

#define SERVICE_NAME (@"me.futurephone.FuturePhone")

@implementation FPMCredentialStore

+ (void)saveSessionKey:(NSString*)sessionKey forPhoneNumber:(NSString*)phoneNumber {
  [[NSUserDefaults standardUserDefaults] setObject:sessionKey forKey:FPM_SESSION_KEY_KEY];
  [self savePhoneNumber:phoneNumber];
}

+ (NSDictionary*)savedSessionKeyAndPhoneNumber {
  NSString* sessionKey = [[NSUserDefaults standardUserDefaults] objectForKey:FPM_SESSION_KEY_KEY];
  NSString* phoneNumber = [self savedPhoneNumber];
  if (phoneNumber && sessionKey) {
    return @{ FPM_PHONE_NUMBER_KEY: phoneNumber,
              FPM_SESSION_KEY_KEY: sessionKey };
  } else {
    return nil;
  }
}

+ (void)savePhoneNumber:(NSString*)phoneNumber {
  [[NSUserDefaults standardUserDefaults] setObject:phoneNumber forKey:FPM_PHONE_NUMBER_KEY];
}

+ (NSString*)savedPhoneNumber {
  return [[NSUserDefaults standardUserDefaults] stringForKey:FPM_PHONE_NUMBER_KEY];
}

+ (void)clearCredentials {
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:FPM_SESSION_KEY_KEY];
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:FPM_PHONE_NUMBER_KEY];
}

#pragma mark - Private

// TODO fix keychain wrapper and actually use it
+ (KeychainItemWrapper*)keychainWrapper {
  static KeychainItemWrapper *keychainWrapper = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    keychainWrapper = [[KeychainItemWrapper alloc] initWithIdentifier:SERVICE_NAME accessGroup:@"futurePhone"];
  });
  return keychainWrapper;
}

+ (NSData*)dataFromString:(NSString*)string {
  return [string dataUsingEncoding:NSUTF8StringEncoding];
}

+ (NSString*)stringFromData:(NSData*)data {
  return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end
