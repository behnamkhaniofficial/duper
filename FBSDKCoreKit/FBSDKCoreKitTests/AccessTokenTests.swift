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

class AccessTokenTests: XCTestCase {

  override func tearDown() {
    super.tearDown()

    AccessToken.current = nil
    AccessToken.connectionFactory = nil
    AccessToken.resetTokenCache()
  }

  func testAccessTokenCacheIsNilByDefault() {
    AccessToken.resetTokenCache()
    XCTAssertNil(AccessToken.tokenCache, "Access token cache should be nil by default")
  }

  func testSetTokenCache() {
    let cache = TestTokenCache(accessToken: nil, authenticationToken: nil)
    AccessToken.tokenCache = cache
    XCTAssertTrue(AccessToken.tokenCache === cache, "Access token cache should be settable")
  }

  func testRetrievingCurrentToken() {
    let cache = TestTokenCache(accessToken: nil, authenticationToken: nil)
    let testToken = SampleAccessTokens.validToken

    AccessToken.tokenCache = cache
    AccessToken.current = testToken

    XCTAssertTrue(cache.accessToken === testToken, "Setting the global access token should invoke the cache")
  }

  func testRefreshTokenThroughTestGraphRequestConnection() {
    let testConnection = TestGraphRequestConnection()
    let factory = TestGraphRequestConnectionFactory.create(withStubbedConnection: testConnection)
    AccessToken.connectionFactory = factory

    AccessToken.current = nil
    AccessToken.refreshCurrentAccessToken(nil)
    XCTAssertEqual(testConnection.startCallCount, 0, "Should not start connection if no current access token available")

    AccessToken.current = SampleAccessTokens.validToken
    AccessToken.refreshCurrentAccessToken(nil)
    XCTAssertEqual(testConnection.startCallCount, 1, "Should start one connection for refreshing")
  }

  func testIsDataAccessExpired() {
    var token = SampleAccessTokens.create(dataAccessExpirationDate: .distantPast)
    XCTAssertTrue(
      token.isDataAccessExpired,
      "A token should have a convenience method for determining if data access is expired"
    )
    token = SampleAccessTokens.create(dataAccessExpirationDate: .distantFuture)
    XCTAssertFalse(
      token.isDataAccessExpired,
      "A token should have a convenience method for determining if data access is unexpired"
    )
  }

  func testSecureCoding() {
    XCTAssertTrue(
      AccessToken.supportsSecureCoding,
      "Access tokens should support secure coding"
    )
  }

  func testEncoding() {
    let coder = TestCoder()
    let token = SampleAccessTokens.validToken
    token.encode(with: coder)

    XCTAssertEqual(
      coder.encodedObject["tokenString"] as? String,
      SampleAccessTokens.validToken.tokenString,
      "Should encode the expected tokenString with the correct key"
    )
    XCTAssertEqual(
      coder.encodedObject["permissions"] as? Set<Permission>,
      SampleAccessTokens.validToken.permissions,
      "Should encode the expected permissions with the correct key"
    )
    XCTAssertEqual(
      coder.encodedObject["declinedPermissions"] as? Set<Permission>,
      SampleAccessTokens.validToken.declinedPermissions,
      "Should encode the expected declinedPermissions with the correct key"
    )
    XCTAssertEqual(
      coder.encodedObject["expiredPermissions"] as? Set<Permission>,
      SampleAccessTokens.validToken.expiredPermissions,
      "Should encode the expected expiredPermissions with the correct key"
    )
    XCTAssertEqual(
      coder.encodedObject["appID"] as? String,
      SampleAccessTokens.validToken.appID,
      "Should encode the expected appID with the correct key"
    )
    XCTAssertEqual(
      coder.encodedObject["userID"] as? String,
      SampleAccessTokens.validToken.userID,
      "Should encode the expected userID with the correct key"
    )
    XCTAssertEqual(
      (coder.encodedObject["refreshDate"] as? Date)?.timeIntervalSince1970,
      token.refreshDate.timeIntervalSince1970,
      "Should encode the expected refreshDate with the correct key"
    )
    XCTAssertEqual(
      (coder.encodedObject["expirationDate"] as? Date)?.timeIntervalSince1970,
      SampleAccessTokens.validToken.expirationDate.timeIntervalSince1970,
      "Should encode the expected expirationDate with the correct key"
    )
    XCTAssertEqual(
      (coder.encodedObject["dataAccessExpirationDate"] as? Date)?.timeIntervalSince1970,
      SampleAccessTokens.validToken.dataAccessExpirationDate.timeIntervalSince1970,
      "Should encode the expected dataAccessExpirationDate with the correct key"
    )
  }

  func testDecoding() {
    let decoder = TestCoder()
    _ = AccessToken(coder: decoder)

    XCTAssertTrue(
      decoder.decodedObject["tokenString"] is NSString.Type,
      "Should decode the expected type for the tokenString key"
    )
    XCTAssertTrue(
      decoder.decodedObject["permissions"] is NSSet.Type,
      "Should decode the expected type for the permissions key"
    )
    XCTAssertTrue(
      decoder.decodedObject["declinedPermissions"] is NSSet.Type,
      "Should decode the expected type for the declinedPermissions key"
    )
    XCTAssertTrue(
      decoder.decodedObject["expiredPermissions"] is NSSet.Type,
      "Should decode the expected type for the expiredPermissions key"
    )
    XCTAssertTrue(
      decoder.decodedObject["appID"] is NSString.Type,
      "Should decode the expected type for the appID key"
    )
    XCTAssertTrue(
      decoder.decodedObject["userID"] is NSString.Type,
      "Should decode the expected type for the userID key"
    )
    XCTAssertTrue(
      decoder.decodedObject["refreshDate"] is NSDate.Type,
      "Should decode the expected type for the refreshDate key"
    )
    XCTAssertTrue(
      decoder.decodedObject["expirationDate"] is NSDate.Type,
      "Should decode the expected type for the expirationDate key"
    )
    XCTAssertTrue(
      decoder.decodedObject["dataAccessExpirationDate"] is NSDate.Type,
      "Should decode the expected type for the dataAccessExpirationDate key"
    )
  }

  func testEquatability() {
    let token1 = SampleAccessTokens.create(withRefreshDate: .distantPast)
    let token2 = SampleAccessTokens.create(withRefreshDate: .distantFuture)
    XCTAssertNotEqual(
      token1,
      token2,
      "Tokens with different values should not be considered equal"
    )
    let token3 = SampleAccessTokens.create(withRefreshDate: .distantPast)
    let token4 = SampleAccessTokens.create(withRefreshDate: .distantPast)
    XCTAssertEqual(
      token3,
      token4,
      "Tokens with the same values should be considered equal"
    )
  }

  func testHashability() {
    let token = SampleAccessTokens.create(withRefreshDate: .distantPast)
    let token2 = SampleAccessTokens.create(withRefreshDate: .distantPast)
    XCTAssertEqual(
      token.hash,
      token2.hash,
      "Token hash values should be predictable and based on the token's properties"
    )
    let token3 = SampleAccessTokens.create(withRefreshDate: .distantFuture)
    XCTAssertNotEqual(
      token.hash,
      token3.hash,
      "Token hash values should be predictable and based on the token's properties"
    )
  }

  func testGrantedPermissions() {
    let token = SampleAccessTokens.create(withPermissions: [name])
    XCTAssertTrue(token.hasGranted(Permission(stringLiteral: name)))
  }

  func testRefreshingNilToken() {
    AccessToken.current = nil
    AccessToken.refreshCurrentAccessToken { potentialConnection, potentialData, potentialError in
      XCTAssertNil(
        potentialConnection,
        "Shouldn't create a connection is there is no token to refresh"
      )
      XCTAssertNil(
        potentialData,
        "Should not call back with data if there is no token to refresh"
      )
      guard let error = potentialError else {
        return XCTFail("Should error when attempting to refresh a nil access token")
      }
      XCTAssertEqual(
        (error as NSError).code,
        CoreError.errorAccessTokenRequired.rawValue,
        "Should return a known error"
      )
    }
  }
}
