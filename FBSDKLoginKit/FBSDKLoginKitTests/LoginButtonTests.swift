// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import FBSDKCoreKit
import TestTools
import XCTest

// swiftlint:disable type_body_length

class LoginButtonTests: XCTestCase {

  let validNonce: String = "abc123"
  var button: FBLoginButton! // swiftlint:disable:this implicitly_unwrapped_optional
  var sampleToken: AuthenticationToken {
    return AuthenticationToken(tokenString: "abc", nonce: "123")
  }

  override func setUp() {
    super.setUp()

    AccessToken.setCurrent(nil, shouldDispatchNotif: false)
    AuthenticationToken.setCurrent(nil)
    Profile.current = nil

    button = FBLoginButton()
  }

  func testDefaultNonce() {
    XCTAssertNil(FBLoginButton().nonce, "Should not have a default nonce")
  }

  func testSettingInvalidNonce() {
    button.nonce = "   "

    XCTAssertNil(
      button.nonce,
      "Should not set an invalid nonce"
    )
  }

  func testSettingValidNonce() {
    button.nonce = validNonce

    XCTAssertEqual(
      button.nonce,
      validNonce,
      "Should set a valid nonce"
    )
  }

  func testLoginConfigurationWithoutNonce() {
    XCTAssertNotNil(
      button.loginConfiguration(),
      "Should be able to create a login configuration without a provided nonce"
    )
  }

  func testLoginConfigurationWithInvalidNonce() {
    button.nonce = "   "

    XCTAssertNotNil(
      button.loginConfiguration(),
      "Should not create a login configuration with an invalid nonce"
    )
  }

  // MARK: - Initial Content Update

  func testInitialContentUpdateWithInactiveAccessTokenWithProfile() {
    let button = TestButton()
    AccessToken.setCurrent(nil, shouldDispatchNotif: false)
    Profile.setCurrent(SampleUserProfiles.valid, shouldPostNotification: false)

    button._initializeContent()

    XCTAssertEqual(
      button.updateContentForProfileCallCount,
      1,
      "Should use the profile when there is no access token"
    )
    XCTAssertEqual(
      button.updateContentForAccessTokenCallCount,
      0,
      "Should not use the access token when there is no access token"
    )
  }

  func testInitialContentUpdateWithActiveAccessTokenWithProfile() {
    let button = TestButton()
    AccessToken.setCurrent(SampleAccessTokens.validToken, shouldDispatchNotif: false)
    let profile = Profile(
      userID: "Sample ID",
      firstName: nil,
      middleName: nil,
      lastName: nil,
      name: "Sample Name",
      linkURL: nil,
      refreshDate: nil
    )
    Profile.setCurrent(profile, shouldPostNotification: false)

    button._initializeContent()

    XCTAssertEqual(
      button.updateContentForProfileCallCount,
      0,
      "Should not use the profile when there is an access token"
    )
    XCTAssertEqual(
      button.updateContentForAccessTokenCallCount,
      1,
      "Should use the access token when there is one available"
    )
  }

  func testInitialContentUpdateWithoutAccessTokenWithoutProfile() {
    let button = TestButton()
    AccessToken.setCurrent(nil, shouldDispatchNotif: false)
    Profile.setCurrent(nil, shouldPostNotification: false)

    button._initializeContent()

    XCTAssertEqual(
      button.updateContentForProfileCallCount,
      0,
      "Should not use the profile when there is no access token or current profile"
    )
    XCTAssertEqual(
      button.updateContentForAccessTokenCallCount,
      0,
      "Should not use the access token when there is no access token or current profile"
    )
    XCTAssertFalse(
      button.isSelected,
      "Should not be selected when there is no access token or current profile"
    )
  }

  // MARK: - Determining Authentication Status

  func testDeterminingAuthenticationWithAccessTokenWithoutAuthToken() {
    AccessToken.setCurrent(SampleAccessTokens.validToken, shouldDispatchNotif: false)

    XCTAssertTrue(
      button._isAuthenticated(),
      "Should consider a user authenticated if they have a current access token"
    )
  }

  func testDeterminingAuthenticationWithoutAccessTokenWithAuthToken() {
    AuthenticationToken.setCurrent(sampleToken)

    XCTAssertTrue(
      button._isAuthenticated(),
      "Should consider a user authenticated if they have a current authentication token"
    )
  }

  // MARK: - Handling Notifications

  func testReceivingAccessTokenNotificationWithDidChangeUserIdKey() {
    let button = TestButton()
    let notification = Notification(
      name: .AccessTokenDidChange,
      object: nil,
      userInfo: [AccessTokenDidChangeUserIDKey: "foo"]
    )

    button._accessTokenDidChange(notification)

    XCTAssertEqual(
      button.updateContentForAccessTokenCallCount,
      1,
      "An access token notification with a changed user id key should trigger a content update"
    )
  }

  func testReceivingAccessTokenNotificationWithTokenDidExpireKey() {
    let button = TestButton()
    let notification = Notification(
      name: .AccessTokenDidChange,
      object: nil,
      userInfo: [AccessTokenDidExpireKey: "foo"]
    )

    button._accessTokenDidChange(notification)

    XCTAssertEqual(
      button.updateContentForAccessTokenCallCount,
      1,
      "An access token notification with an expired token key should trigger a content update"
    )
  }

  func testReceivingAccessTokenNotificationWithoutRelevantUserInfo() {
    let button = TestButton()
    let notification = Notification(
      name: .AccessTokenDidChange,
      object: nil,
      userInfo: nil
    )

    button._accessTokenDidChange(notification)

    XCTAssertEqual(
      button.updateContentForAccessTokenCallCount,
      0,
      "An access token notification without relevant user info should not trigger a content update"
    )
  }

  func testReceivingProfileNotification() {
    let button = TestButton()
    let notification = Notification(
      name: .ProfileDidChange,
      object: nil,
      userInfo: nil
    )

    button._profileDidChange(notification)

    XCTAssertEqual(
      button.updateContentForProfileCallCount,
      1,
      "An profile change should trigger a content update"
    )
  }

  // MARK: - Updating Content

  func testUpdatingContentWithMissingProfile() {
    button._updateContent(forUserProfile: nil)

    XCTAssertFalse(
      button.isSelected,
      "Should not be selected if there is not a profile"
    )
    XCTAssertNil(button.userName())
    XCTAssertNil(button.userID())
  }

  func testUpdatingContentWithProfile() {
    button._updateContent(forUserProfile: SampleUserProfiles.valid)

    XCTAssertTrue(
      button.isSelected,
      "Should be selected if there is a valid profile"
    )
    XCTAssertEqual(button.userName(), SampleUserProfiles.valid.name)
    XCTAssertEqual(button.userID(), SampleUserProfiles.valid.userID)
  }

  func testUpdatingContentForProfileWithNewId() {
    let button = TestButton()
    let profile = SampleUserProfiles.createValid(name: name)
    button._updateContent(forUserProfile: SampleUserProfiles.valid)
    button._updateContent(forUserProfile: profile)

    XCTAssertEqual(
      button.userName(),
      profile.name,
      "Should update the user information with the updated profile information"
    )
    XCTAssertEqual(
      button.userID(),
      profile.userID,
      "Should update the user information with the updated profile information"
    )
  }

  func testUpdatingContentForProfileWithNewName() {
    let button = TestButton()
    let profile = SampleUserProfiles.createValid(name: name)
    button._updateContent(forUserProfile: SampleUserProfiles.valid)
    button._updateContent(forUserProfile: profile)

    XCTAssertEqual(
      button.userName(),
      profile.name,
      "Should update the user information with the updated profile information"
    )
    XCTAssertEqual(
      button.userID(),
      profile.userID,
      "Should update the user information with the updated profile information"
    )
  }

  func testUpdatingContentWithValidAccessToken() {
    let button = TestButton()
    AccessToken.setCurrent(SampleAccessTokens.validToken, shouldDispatchNotif: false)

    button._updateContentForAccessToken()

    XCTAssertEqual(
      button.fetchAndSetContentCallCount,
      1,
      "Should try to fetch content for a valid access token"
    )
  }

  func testUpdatingContentWithInvalidAccessToken() {
    let button = TestButton()
    AccessToken.setCurrent(SampleAccessTokens.expiredToken, shouldDispatchNotif: false)

    button._updateContentForAccessToken()
    button._updateContentForAccessToken()

    XCTAssertEqual(
      button.fetchAndSetContentCallCount,
      0,
      "Should not try to fetch content for an invalid access token"
    )
  }

  func testUpdatingContentWithIdenticalAccessToken() {
    let button = TestButton()

    // Make sure the username and id properties on button are set to the same values
    // as the access token. This is an easy way to do with without having to stub
    // a network call
    let profile = SampleUserProfiles.createValid(userID: SampleAccessTokens.validToken.userID)
    button._updateContent(forUserProfile: profile)

    AccessToken.setCurrent(SampleAccessTokens.validToken, shouldDispatchNotif: false)

    button._updateContentForAccessToken()

    XCTAssertEqual(
      button.fetchAndSetContentCallCount,
      0,
      "Should not try to fetch content for a token if the user identifier has not changed"
    )
  }
}

private class TestButton: FBLoginButton {
  var fetchAndSetContentCallCount = 0
  var updateContentForAccessTokenCallCount = 0
  var updateContentForProfileCallCount = 0

  override func _updateContentForAccessToken() {
    updateContentForAccessTokenCallCount += 1

    super._updateContentForAccessToken()
  }

  override func _updateContent(forUserProfile profile: Profile?) {
    updateContentForProfileCallCount += 1

    super._updateContent(forUserProfile: profile)
  }

  override func _fetchAndSetContent() {
    fetchAndSetContentCallCount += 1
  }
}
