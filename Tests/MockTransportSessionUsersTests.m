// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
// 


#import "MockTransportSessionTests.h"
@import WireMockTransport;

@interface MockTransportSessionUsersTests : MockTransportSessionTests

@end

@implementation MockTransportSessionUsersTests

- (void)testThatACreatedUserHasValidatedEmail
{
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        // WHEN
        MockUser *user = [session insertUserWithName:@"Mario"];
        
        // THEN
        XCTAssertTrue(user.isEmailValidated);
    }];
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testCreatingAndRequestingSeveralUsers;
{
    // GIVEN
    __block MockUser *selfUser;
    __block MockUser *user1;
    __block MockUser *user2;
    __block MockUser *user3;
    
    __block MockConnection *connection1;
    __block MockConnection *connection2;
    __block MockConnection *connection3;
    
    __block NSString *user1ID;
    __block NSString *user2ID;
    __block NSString *user3ID;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
        user1 = [session insertUserWithName:@"Bar"];
        user1.email = @"";
        user1.accentID = 2;
        user1.phone = @"";
        user1.previewProfileAssetIdentifier = @"123";
        user1.completeProfileAssetIdentifier = @"4556";
        user1ID = user1.identifier;
        
        connection1 = [session insertConnectionWithSelfUser:selfUser toUser:user1];
        connection1.status = @"accepted";
        connection1.lastUpdate = [NSDate dateWithTimeIntervalSince1970:1399920861.091];
        
        user2 = [session insertUserWithName:@"Baz"];
        user2.email = @"";
        user2.accentID = 3;
        user2.phone = @"";
        user2ID = user2.identifier;
        
        connection2 = [session insertConnectionWithSelfUser:selfUser toUser:user2];
        connection2.status = @"accepted";
        connection2.lastUpdate = [NSDate dateWithTimeIntervalSince1970:1399920870.091];
        
        user3 = [session insertUserWithName:@"Quux"];
        user3.email = @"";
        user3.accentID = 1;
        user3.phone = @"";
        user3.previewProfileAssetIdentifier = @"0099";
        user3.completeProfileAssetIdentifier = @"29993";
        user3ID = user3.identifier;
        
        connection3 = [session insertConnectionWithSelfUser:selfUser toUser:user3];
        connection3.status = @"accepted";
        connection3.lastUpdate = [NSDate dateWithTimeIntervalSince1970:1399920880.091];
        
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    NSString *path = [NSString stringWithFormat:@"/users/?ids=%@,%@,%@", [user1ID lowercaseString], [user2ID uppercaseString], user3ID];
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET];
    
    // THEN
    XCTAssertNotNil(response);
    if (!response) {
        return;
    }
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertNil(response.transportSessionError);
    XCTAssertTrue([response.payload isKindOfClass:[NSArray class]]);
    
    NSArray *data = (id) response.payload;
    XCTAssertEqual(data.count, 3u);
    
    if (3 <= data.count) {
        [self checkThatTransportData:data[0] matchesUser:user1 isSelfUser:NO failureRecorder:NewFailureRecorder()];
        [self checkThatTransportData:data[1] matchesUser:user2 isSelfUser:NO failureRecorder:NewFailureRecorder()];
        [self checkThatTransportData:data[2] matchesUser:user3 isSelfUser:NO failureRecorder:NewFailureRecorder()];
    }
}

- (void)testCreatingAndRequestingSelfUser;
{
    // GIVEN
    __block MockUser *selfUser;
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
        selfUser.email = @"foo@example.com";
        selfUser.phone = @"+4555575653498";
        selfUser.accentID = 4;
        selfUser.previewProfileAssetIdentifier = @"1234-1";
        selfUser.completeProfileAssetIdentifier = @"0987-1";
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    NSString *path = @"/self";
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET];
    
    // THEN
    XCTAssertNotNil(response);
    if (!response) {
        return;
    }
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertNil(response.transportSessionError);
    XCTAssertTrue([response.payload isKindOfClass:[NSDictionary class]]);
    NSDictionary *data = (id) response.payload;
    
    [self checkThatTransportData:data matchesUser:selfUser isSelfUser:YES failureRecorder:NewFailureRecorder()];
}

- (void)testThatItCreatesHandleForSelfUser
{
    // GIVEN
    __block MockUser *selfUser;
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    NSString *path = @"/self";
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET];
    
    // THEN
    XCTAssertNotNil(response);
    if (!response) {
        return;
    }
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertNil(response.transportSessionError);
    XCTAssertTrue([response.payload isKindOfClass:[NSDictionary class]]);
    NSDictionary *data = (id) response.payload;
    XCTAssertNotNil([data stringForKey:@"handle"]);
    XCTAssertGreaterThan([data stringForKey:@"handle"].length, 5u);
}

- (void)testThatItCreatesHandleForAnyUser
{
    // GIVEN
    __block MockUser *user;
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        user = [session insertUserWithName:@"Foo"];
        user.identifier = [NSUUID createUUID].transportString;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    NSString *path = [@"/users/" stringByAppendingPathComponent:user.identifier];
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET];
    
    // THEN
    XCTAssertNotNil(response);
    if (!response) {
        return;
    }
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertNil(response.transportSessionError);
    XCTAssertTrue([response.payload isKindOfClass:[NSDictionary class]]);
    NSDictionary *data = (id) response.payload;
    XCTAssertNotNil([data stringForKey:@"handle"]);
    XCTAssertGreaterThan([data stringForKey:@"handle"].length, 5u);
}


- (void)testCreatingAndRequestingConnectedUser;
{
    // GIVEN
    __block MockUser *selfUser;
    __block MockUser *user1;
    
    __block MockConnection *connection1;
    __block NSString *user1ID;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
        user1 = [session insertUserWithName:@"Bar"];
        user1.email = @"barfooz@example.com";
        user1.accentID = 7;
        user1.phone = @"+4954334535345345345";
        [session addProfilePictureToUser:user1];
        [user1.managedObjectContext obtainPermanentIDsForObjects:@[user1] error:NULL];
        user1ID = user1.identifier;
        
        connection1 = [session insertConnectionWithSelfUser:selfUser toUser:user1];
        connection1.status = @"accepted";
        connection1.lastUpdate = [NSDate dateWithTimeIntervalSince1970:1399920861.091];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    NSString *path = [@"/users/" stringByAppendingPathComponent:user1ID];
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET];
    
    // THEN
    XCTAssertNotNil(response);
    if (!response) {
        return;
    }
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertNil(response.transportSessionError);
    XCTAssertTrue([response.payload isKindOfClass:[NSDictionary class]]);
    NSDictionary *data = (id) response.payload;
    
    [self checkThatTransportData:data matchesUser:user1 isSelfUser:NO failureRecorder:NewFailureRecorder()];
}

- (void)testCreatingAndRequestingNonConnectedUser;
{
    // GIVEN
    __block MockUser *selfUser;
    __block MockUser *user1;
    
    __block NSString *user1ID;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
        user1 = [session insertUserWithName:@"Bar"];
        user1.email = @"barfooz@example.com";
        user1.accentID = 7;
        user1.phone = @"+4954334535345345345";
        [session addProfilePictureToUser:user1];
        [user1.managedObjectContext obtainPermanentIDsForObjects:@[user1] error:NULL];
        user1ID = user1.identifier;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    NSString *path = [@"/users/" stringByAppendingPathComponent:user1ID];
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET];
    
    // THEN
    XCTAssertNotNil(response);
    if (!response) {
        return;
    }
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertNil(response.transportSessionError);
    XCTAssertTrue([response.payload isKindOfClass:[NSDictionary class]]);
    NSDictionary *data = (id) response.payload;
    
    [self checkThatTransportData:data matchesUser:user1 isSelfUser:NO failureRecorder:NewFailureRecorder()];
}

- (void)testThatItUpdatesTheSelfUserOnPUT
{
    // GIVEN
    __block MockUser *selfUser;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
        selfUser.accentID = 8;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSString *previewId = @"123-45";
    NSString *completeId = @"09873-1";
    NSDictionary *payload = @{
                              @"name" : @"This is the new name",
                              @"accent_id" : @"4",
                              @"assets" : @[
                                           @{ @"key" : previewId, @"type" : @"image", @"size" : @"preview" },
                                           @{ @"key" : completeId, @"type" : @"image", @"size" : @"complete" },
                                             ]
                              };
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/self" method:ZMMethodPUT];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertNil(response.payload);
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        NOT_USED(session);
        XCTAssertEqualObjects(selfUser.name, payload[@"name"]);
        XCTAssertEqual(selfUser.accentID, [payload[@"accent_id"] integerValue] );
        XCTAssertEqualObjects(selfUser.previewProfileAssetIdentifier, previewId);
        XCTAssertEqualObjects(selfUser.completeProfileAssetIdentifier, completeId);
    }];
    WaitForAllGroupsToBeEmpty(0.5);
}

@end



@implementation MockTransportSessionUsersTests (UserProfileUpdate)

- (void)testThatItPutsTheEmail
{
    // GIVEN
    __block MockUser *selfUser;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
    }];
    NSString *email = @"foo@bar.bar";
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:@{@"email":email} path:@"/self/email" method:ZMMethodPUT];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 200);
    // this will send out a validation email, not set the email directly, so we can't test that the email changed on the user
    XCTAssertNil(self.sut.selfUser.email);
}

- (void)testThatDoesNotPutTheEmailAndReturns400IfTheEmailIsMissing
{
    // GIVEN
    __block MockUser *selfUser;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
    }];
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:@{} path:@"/self/email" method:ZMMethodPUT];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 400);
    XCTAssertNil(self.sut.selfUser.email);
}

- (void)testThatItDoesNotPutTheEmailAndReturns409IfThereIsAlreadyAUserWithThatEmail
{
    // GIVEN
    __block MockUser *selfUser;
    NSString *email = @"foo@bar.bar";
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
        MockUser *otherUser = [session insertUserWithName:@"Beth"];
        otherUser.email = email;
    }];
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:@{@"email":email} path:@"/self/email" method:ZMMethodPUT];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 409);
    XCTAssertNil(self.sut.selfUser.email);
}

- (void)testThatItPutsThePassword
{
    // GIVEN
    __block MockUser *selfUser;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
    }];
    NSString *password = @"12%$#%";
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:@{@"new_password":password} path:@"/self/password" method:ZMMethodPUT];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertEqualObjects(self.sut.selfUser.password, password);
}

- (void)testThatDoesNotPutThePasswordAndReturns400IfThePasswordlIsMissing
{
    // GIVEN
    __block MockUser *selfUser;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
    }];
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:@{} path:@"/self/passwprd" method:ZMMethodPUT];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 400);
}

- (void)testThatItDoesNotPutThePasswordIfthePasswordIsAlreadyThereAndTheOldPasswordDoesNotMatch
{
    // GIVEN
    __block MockUser *selfUser;
    NSString *formerPassword = @"324324234";
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
        selfUser.password = formerPassword;
    }];
    NSString *password = @"12%$#%";
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:@{@"old_password":password, @"new_password":password} path:@"/self/password" method:ZMMethodPUT];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 403);
    XCTAssertEqualObjects(self.sut.selfUser.password, formerPassword);
}

- (void)testThatItDoesPutThePasswordIfthePasswordIsAlreadyAndTheOldPasswordMatches
{
    // GIVEN
    __block MockUser *selfUser;
    NSString *formerPassword = @"324324234";
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
        selfUser.password = formerPassword;
    }];
    NSString *password = @"12%$#%";
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:@{@"old_password":formerPassword, @"new_password":password} path:@"/self/password" method:ZMMethodPUT];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertEqualObjects(self.sut.selfUser.password, password);
}

- (void)testThatItPostsARequestToGetTheProfilePhoneCodeAndUsesItToActivateThePhone
{
    // GIVEN
    __block MockUser *selfUser;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
    }];
    NSString *phone = @"+99123245";
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:@{@"phone":phone} path:@"/self/phone" method:ZMMethodPUT];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertTrue([self.sut.phoneNumbersWaitingForVerificationForProfile containsObject:phone]);
    
    // and when
    response = [self responseForPayload:@{@"phone":phone, @"code":self.sut.phoneVerificationCodeForUpdatingProfile} path:@"/activate" method:ZMMethodPOST];

    // THEN
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertFalse([self.sut.phoneNumbersWaitingForVerificationForProfile containsObject:phone]);

}

- (void)testThatItPostsARequestToGetTheProfilePhoneCodeAndReturns409IfDuplicated
{
    // GIVEN
    __block MockUser *selfUser;
    NSString *phone = @"+99123245";
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
        MockUser *otherUser = [session insertUserWithName:@"Gabrielle"];
        otherUser.phone = phone;
    }];
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:@{@"phone":phone} path:@"/self/phone" method:ZMMethodPUT];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 409);
    XCTAssertFalse([self.sut.phoneNumbersWaitingForVerificationForProfile containsObject:phone]);
}

- (void)testThatDoesNotPutThePhoneAndReturns400IfThePhonelIsMissing
{
    // GIVEN
    __block MockUser *selfUser;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
    }];
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:@{} path:@"/self/phone" method:ZMMethodPUT];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 400);
}

- (void)testThatItPutsTheHandle
{
    // GIVEN
    __block MockUser *selfUser;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
    }];
    NSString *handle = @"aaa12";
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:@{@"handle":handle} path:@"/self/handle" method:ZMMethodPUT];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertEqualObjects(selfUser.handle, handle);
}

- (void)testThatDoesNotPutTheHandleIfItExistsAlready
{
    // GIVEN
    __block MockUser *selfUser;
    __block MockUser *otherUser;
    NSString *initialHandle = @"initial33";
    NSString *handle = @"foobar22222";
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
        selfUser.handle = initialHandle;
        otherUser = [session insertUserWithName:@"The other"];
        otherUser.handle = handle;
    }];
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:@{@"handle":handle} path:@"/self/handle" method:ZMMethodPUT];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 409);
    XCTAssertEqualObjects(response.payloadLabel, @"key-exists");
    XCTAssertEqualObjects(selfUser.handle, initialHandle);
    XCTAssertEqualObjects(otherUser.handle, handle);

}

- (void)testThatItFindsAnExhistingHandle_GET
{
    // GIVEN
    NSString *handle = @"foobar22222";
    __block MockUser *user;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        user = [session insertUserWithName:@"The other"];
        user.handle = handle;
    }];
    
    // WHEN
    NSString *path = [@"/users/handles/" stringByAppendingPathComponent:handle];
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 200);
    [self checkThatTransportData:response.payload matchesUser:user isSelfUser:NO failureRecorder:NewFailureRecorder()];
}

- (void)testThatItFindsAnExhistingHandle_HEAD
{
    // GIVEN
    NSString *handle = @"foobar22222";
    __block MockUser *user;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        user = [session insertUserWithName:@"The other"];
        user.handle = handle;
    }];
    
    // WHEN
    NSString *path = [@"/users/handles/" stringByAppendingPathComponent:handle];
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodHEAD];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertEqualObjects(response.rawResponse.URL.path, path);
    [self checkThatTransportData:response.payload matchesUser:user isSelfUser:NO failureRecorder:NewFailureRecorder()];
}

- (void)testThatItDoesNotFindANonExhistingHandle
{
    // GIVEN
    NSString *handle = @"foobar22222";
    
    // WHEN
    NSString *path = [@"/users/handles/" stringByAppendingPathComponent:handle];
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 404);
    XCTAssertEqualObjects(response.rawResponse.URL.path, path);
}

- (void)testThatItChecksHandleAvailability
{
    // GIVEN
    NSString *existingHandle = @"foobar22222";
    NSString *nonExistingHandle = @"notthere";
    __block MockUser *user;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        user = [session insertUserWithName:@"The other"];
        user.handle = existingHandle;
    }];
    
    // WHEN
    NSDictionary *payload = @{
                              @"return" : @1,
                              @"handles" : @[existingHandle, nonExistingHandle]
                              };
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/users/handles/" method:ZMMethodPOST];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 200);
    NSArray *result = [response.payload asArray];
    XCTAssertEqualObjects(result, @[nonExistingHandle]);
}

- (void)testThatItFailsToCheckHandleAvailabilityWhenRequestHasNoReturnValue
{
    // GIVEN
    NSString *existingHandle = @"foobar22222";
    NSString *nonExistingHandle = @"notthere";
    __block MockUser *user;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        user = [session insertUserWithName:@"The other"];
        user.handle = existingHandle;
    }];
    
    // WHEN
    NSDictionary *payload = @{
                              @"handles" : @[existingHandle, nonExistingHandle]
                              };
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/users/handles/" method:ZMMethodPOST];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 400);
}

- (void)testThatItFailsToCheckHandleAvailabilityWhenRequestHasNoHandlesValue
{
    // GIVEN
    NSString *existingHandle = @"foobar22222";
    __block MockUser *user;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        user = [session insertUserWithName:@"The other"];
        user.handle = existingHandle;
    }];
    
    // WHEN
    NSDictionary *payload = @{
                              @"return" : @12
                              };
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/users/handles/" method:ZMMethodPOST];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 400);
}

- (void)testThatItCheckHandleAvailabilityAndReturnEmptyResult
{
    // GIVEN
    NSString *existingHandle = @"foobar22222";
    __block MockUser *user;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        user = [session insertUserWithName:@"The other"];
        user.handle = existingHandle;
    }];
    
    // WHEN
    NSDictionary *payload = @{
                              @"return" : @1,
                              @"handles" : @[existingHandle]
                              };
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/users/handles/" method:ZMMethodPOST];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 200);
    NSArray *result = [response.payload asArray];
    XCTAssertEqualObjects(result, @[]);
}


@end

@implementation MockTransportSessionUsersTests (OTR)

- (void)testThatItReturnsUserClientsKeys
{
    __block MockUser *selfUser;
    __block MockUser *otherUser;
    __block MockUser *thirdUser;
    __block MockUserClient *selfClient;
    __block MockUserClient *otherUserClient;
    __block MockUserClient *secondOtherUserClient;
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"foo"];
        otherUser = [session insertUserWithName:@"bar"];
        thirdUser = [session insertUserWithName:@"foobar"];
        selfClient = [session registerClientForUser:selfUser label:@"self1" type:@"permanent"];
        otherUserClient = [session registerClientForUser:otherUser label:@"other1" type:@"permanent"];
        secondOtherUserClient = [session registerClientForUser:otherUser label:@"other2" type:@"permanent"];
    }];
    
    NSString *redunduntClientId = [NSString createAlphanumericalString];
    NSDictionary *payload = @{selfUser.identifier: @[selfClient.identifier, redunduntClientId], otherUser.identifier: @[otherUserClient.identifier, secondOtherUserClient.identifier], thirdUser.identifier: @[redunduntClientId]};
    
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/users/prekeys" method:ZMMethodPOST];
    XCTAssertEqual(response.HTTPStatus, 200);

    NSArray *exepctedUsers = @[selfUser.identifier, otherUser.identifier];
    AssertDictionaryHasKeys(response.payload.asDictionary, exepctedUsers);
    NSArray *expectedClients = @[selfClient.identifier];
    AssertDictionaryHasKeys(response.payload.asDictionary[selfUser.identifier], expectedClients);
    expectedClients = @[otherUserClient.identifier, secondOtherUserClient.identifier];
    AssertDictionaryHasKeys(response.payload.asDictionary[otherUser.identifier], expectedClients);
}

@end

