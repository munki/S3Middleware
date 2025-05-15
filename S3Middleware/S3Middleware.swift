//
//  S3Middleware.swift
//  S3Middleware
//
//  Created by Greg Neagle on 5/11/25.
//
//  A proof-of-concept port of Wade Robson's s3 auth middleware
//  https://github.com/waderobson/s3-auth
//

import CryptoKit
import Foundation

let BUNDLE_ID = "ManagedInstalls" as CFString

/// read a preference
func pref(_ prefName: String) -> Any? {
    return CFPreferencesCopyAppValue(prefName as CFString, BUNDLE_ID)
}

func sha256hash(data: Data) -> String {
    let hashed = SHA256.hash(data: data)
    return hashed.compactMap { String(format: "%02x", $0) }.joined()
}

func sign(key: Data, message: String) -> Data {
    let messageData = Data(message.utf8)
    let authenticationCode = HMAC<SHA256>.authenticationCode(for: messageData, using: SymmetricKey(data: key))
    return Data(authenticationCode)
}

func getSignatureKey(key: String, datestamp: String, region: String) -> Data {
    let keyData = Data("AWS4\(key)".utf8)
    let kdate = sign(key: keyData, message: datestamp)
    let kregion = sign(key: kdate, message: region)
    let kservice = sign(key: kregion, message: "s3")
    let signatureKey = sign(key: kservice, message: "aws4_request")
    return signatureKey
}

/// Returns a dict that contains all the required header information.
/// Each header is unique to the url requested.
func s3AuthHeaders(_ url: String) -> [String: String] {
    // better be a parsable url
    guard let parsedURL = URL(string: url) else {
        return [:]
    }
    // read some prefs
    let accessKey = pref("AccessKey") as? String ?? ""
    let secretKey = pref("SecretKey") as? String ?? ""
    let region = pref("Region") as? String ?? ""
    // make some datestamps
    let now = Date()
    let dateFormatter = DateFormatter()
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    dateFormatter.dateFormat = "yyyMMdd'T'HHmmss'Z'"
    let amzDate = dateFormatter.string(from: now)
    dateFormatter.dateFormat = "yyyMMdd"
    let datestamp = dateFormatter.string(from: now)
    // start getting the components we need to build the
    // auth headers
    let method = "GET"
    let canonicalURI = parsedURL.path
    let host = parsedURL.host ?? ""
    let canonicalizedQueryString = ""
    let canonicalHeaders = "host:\(host)\nx-amz-date:\(amzDate)\n"
    let signedHeaders = "host;x-amz-date"
    let payloadHash = sha256hash(data: Data())
    let canonicalRequest = [
        method,
        canonicalURI,
        canonicalizedQueryString,
        canonicalHeaders,
        signedHeaders,
        payloadHash,
    ].joined(separator: "\n")
    let algorithm = "AWS4-HMAC-SHA256"
    let credentialScope = "\(datestamp)/\(region)/s3/aws4_request"
    let hashedRequest = sha256hash(data: Data(canonicalRequest.utf8))
    let stringToSign = "\(algorithm)\n\(amzDate)\n\(credentialScope)\n\(hashedRequest)"
    let signingKey = getSignatureKey(key: secretKey, datestamp: datestamp, region: region)
    let signature = HMAC<SHA256>.authenticationCode(
        for: Data(stringToSign.utf8),
        using: SymmetricKey(data: signingKey)
    ).compactMap { String(format: "%02x", $0) }.joined()
    let authorizationHeader = "\(algorithm) Credential=\(accessKey)/\(credentialScope), SignedHeaders=\(signedHeaders), Signature=\(signature)"
    let headers = [
        "x-amz-date": amzDate,
        "x-amz-content-sha256": payloadHash,
        "Authorization": authorizationHeader,
    ]
    return headers
}

/// Adds a shared access signature to the request URL
class S3Middleware: MunkiMiddleware {
    func processRequest(_ request: MunkiMiddlewareRequest) -> MunkiMiddlewareRequest {
        let s3endpoint = pref("S3Endpoint") as? String ?? "s3.amazonaws.com"
        var modifiedRequest = request
        if modifiedRequest.url.contains(s3endpoint) {
            let s3headers = s3AuthHeaders(request.url)
            modifiedRequest.headers.merge(s3headers, uniquingKeysWith: { _, new in new })
        }
        return modifiedRequest
    }
}

// MARK: dylib "interface"

/// Function with C calling style for our dylib. We use it to instantiate the Repo object and return an instance
@_cdecl("createPlugin")
public func createPlugin() -> UnsafeMutableRawPointer {
    return Unmanaged.passRetained(S3MiddlewareBuilder()).toOpaque()
}

final class S3MiddlewareBuilder: MiddlewarePluginBuilder {
    override func create() -> MunkiMiddleware {
        return S3Middleware()
    }
}
