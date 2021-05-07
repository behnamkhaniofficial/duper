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

class TestBridgeApiProtocol: NSObject, BridgeAPIProtocol {
  var stubbedRequestURL = SampleUrls.valid
  var stubbedResponseParameters = [AnyHashable: Any]()
  var capturedRequestUrlActionID: String?
  var capturedRequestUrlScheme: String?
  var capturedRequestUrlMethodName: String?
  var capturedRequestUrlMethodVersion: String?
  var capturedRequestUrlParameters: [AnyHashable: Any]?
  var capturedResponseActionID: String?
  var capturedResponseQueryParameters: [AnyHashable: Any]?
  var capturedResponseCancelledRef: UnsafeMutablePointer<ObjCBool>?

  func requestURL(
    withActionID actionID: String,
    scheme: String,
    methodName: String,
    methodVersion: String,
    parameters: [AnyHashable: Any]
  ) throws -> URL {
    capturedRequestUrlActionID = actionID
    capturedRequestUrlScheme = scheme
    capturedRequestUrlMethodName = methodName
    capturedRequestUrlMethodVersion = methodVersion
    capturedRequestUrlParameters = parameters

    return stubbedRequestURL
  }

  func responseParameters(
    forActionID actionID: String,
    queryParameters: [AnyHashable: Any],
    cancelled cancelledRef: UnsafeMutablePointer<ObjCBool>
  ) throws -> [AnyHashable: Any] {
    capturedResponseActionID = actionID
    capturedResponseQueryParameters = queryParameters
    capturedResponseCancelledRef = cancelledRef

    return stubbedResponseParameters
  }
}
