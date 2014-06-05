//
//  FPMCredentialStoreTests.m
//  FuturePhone
//
//  Created by alden on 6/1/14.
//  Copyright (c) 2014 futurephone. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "FPMCredentialStore.h"

@interface FPMCredentialStoreTests : XCTestCase

@end

@implementation FPMCredentialStoreTests

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testSaveAndReadSessionAndPhone {
  [FPMCredentialStore saveSessionKey:@"sessionkey" forPhoneNumber:@"11111111111"];
  NSDictionary* saved = [FPMCredentialStore savedSessionKeyAndPhoneNumber];
  NSString* savedPhone = saved[FPM_PHONE_NUMBER_KEY];
  NSString* savedSession = saved[FPM_SESSION_KEY_KEY];
  XCTAssertEqualObjects(savedSession, @"sessionkey");
  XCTAssertEqualObjects(savedPhone, @"11111111111");
}

- (void)testClearSessionAndPhone {
  [FPMCredentialStore saveSessionKey:@"sessionkey" forPhoneNumber:@"11111111111"];
  [FPMCredentialStore clearCredentials];
  NSDictionary* saved = [FPMCredentialStore savedSessionKeyAndPhoneNumber];
  XCTAssertNil(saved);
}

@end
