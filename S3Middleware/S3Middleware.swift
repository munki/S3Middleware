//
//  S3Middleware.swift
//  S3Middleware
//
//  Created by Greg Neagle on 5/11/25.
//
//  A proof-of-concept port of Wade Robson's s3 auth middleware
//  https://github.com/waderobson/s3-auth
//
// Amazon's documentation here:
// https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_sigv-create-signed-request.html#sig-v4-examples-get-auth-header

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

class S3RequestHeadersBuilder {
    let url: URL
    let amzDate: String
    let datestamp: String
    let signedHeaders = "host;x-amz-date"
    let algorithm = "AWS4-HMAC-SHA256"
    let payloadHash = sha256hash(data: Data())
    let accessKey: String
    let secretKey: String
    let region: String
    var credentialScope: String
    var hashedRequest: String = ""

    /// Primary init method
    init?(url: String) {
        // makre sure we have a valid URL
        guard let parsedURL = URL(string: url) else {
            return nil
        }
        self.url = parsedURL

        // set our datestamps
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyMMdd'T'HHmmss'Z'"
        amzDate = dateFormatter.string(from: now)
        dateFormatter.dateFormat = "yyyMMdd"
        datestamp = dateFormatter.string(from: now)

        // read some prefs
        accessKey = pref("AccessKey") as? String ?? ""
        secretKey = pref("SecretKey") as? String ?? ""
        region = pref("Region") as? String ?? ""

        // set credential scope
        credentialScope = "\(datestamp)/\(region)/s3/aws4_request"
        // populate hashedRequest
        createCanonicalRequestHash()
    }

    /// used only for testing
    init(url: URL, amzDate: String, datestamp: String, accessKey: String, secretKey: String, region: String) {
        self.url = url
        self.amzDate = amzDate
        self.datestamp = datestamp
        self.accessKey = accessKey
        self.secretKey = secretKey
        self.region = region
        // set credential scope
        credentialScope = "\(datestamp)/\(region)/s3/aws4_request"
        // populate hashedRequest
        createCanonicalRequestHash()
    }

    /// build a canonical request string
    func createCanonicalRequestHash() {
        let method = "GET"
        let canonicalURI = url.path
        let host = url.host ?? ""
        let canonicalizedQueryString = url.query ?? ""
        let canonicalHeaders = "host:\(host)\nx-amz-date:\(amzDate)\n"
        let canonicalRequest = [
            method,
            canonicalURI,
            canonicalizedQueryString,
            canonicalHeaders,
            signedHeaders,
            payloadHash,
        ].joined(separator: "\n")
        hashedRequest = sha256hash(data: Data(canonicalRequest.utf8))
    }

    /// create a signing key for the request signature
    func createSignatureKey() -> Data {
        let keyData = Data("AWS4\(secretKey)".utf8)
        let kdate = sign(key: keyData, message: datestamp)
        let kregion = sign(key: kdate, message: region)
        let kservice = sign(key: kregion, message: "s3")
        let signatureKey = sign(key: kservice, message: "aws4_request")
        return signatureKey
    }

    /// generate string to sign
    func stringToSign() -> String {
        return "\(algorithm)\n\(amzDate)\n\(credentialScope)\n\(hashedRequest)"
    }

    /// create a signature for the request
    func createSignature() -> String {
        let signingKey = createSignatureKey()
        return sign(key: signingKey, message: stringToSign()).compactMap { String(format: "%02x", $0)
        }.joined()
    }

    /// create the actual S3 headers needed for the request
    func createHeaders() -> [String: String] {
        let signature = createSignature()
        let authorizationHeader = "\(algorithm) Credential=\(accessKey)/\(credentialScope), SignedHeaders=\(signedHeaders), Signature=\(signature)"

        let headers = [
            "x-amz-date": amzDate,
            "x-amz-content-sha256": payloadHash,
            "Authorization": authorizationHeader,
        ]
        return headers
    }
}

/// Adds a shared access signature to the request URL
class S3Middleware: MunkiMiddleware {
    func processRequest(_ request: MunkiMiddlewareRequest) -> MunkiMiddlewareRequest {
        let s3endpoint = pref("S3Endpoint") as? String ?? "s3.amazonaws.com"
        var modifiedRequest = request
        if modifiedRequest.url.contains(s3endpoint) {
            if let headersBuilder = S3RequestHeadersBuilder(url: modifiedRequest.url) {
                let s3headers = headersBuilder.createHeaders()
                modifiedRequest.headers.merge(s3headers, uniquingKeysWith: {
                    _, new in new
                })
            }
        }
        return modifiedRequest
    }
}

// MARK: dylib "interface"

final class S3MiddlewareBuilder: MiddlewarePluginBuilder {
    override func create() -> MunkiMiddleware {
        return S3Middleware()
    }
}

/// Function with C calling style for our dylib.
/// We use it to instantiate the MunkiMiddleware object and return an instance
@_cdecl("createPlugin")
public func createPlugin() -> UnsafeMutableRawPointer {
    return Unmanaged.passRetained(S3MiddlewareBuilder()).toOpaque()
}
