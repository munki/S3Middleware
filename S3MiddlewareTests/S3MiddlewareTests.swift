//
//  S3MiddlewareTests.swift
//  S3MiddlewareTests
//
//  Created by Greg Neagle on 5/15/25.
//

import CryptoKit
import Foundation
import Testing

struct S3MiddlewareTests {
    /// a consistent text fixture
    func headersBuilder() -> S3RequestHeadersBuilder {
        return S3RequestHeadersBuilder(
            url: URL(string: "https://example.com")!,
            amzDate: "20250513T150921Z",
            datestamp: "20250513",
            accessKey: "FOO",
            secretKey: "FOO",
            region: "BAR"
        )
    }

    /// This simply tests that the sign function produces the same output as in
    /// the Python version of this plugin
    @Test func signGeneratesExpected() {
        let key = sign(key: Data("FOO".utf8), message: "BAR").base64EncodedString()
        #expect(key == "fk+tOTds7rkT7JbQxHyqlAw5745HM/T6PNUe4/V9WVU=")
    }

    /// This simply tests that the generated signing key matches that generated
    /// by the Python version of this plugin
    @Test func getSignatureKeyGeneratesExpected() {
        let signingKey = headersBuilder().createSignatureKey()

        #expect(signingKey.base64EncodedString() == "PfLOPqq9IZ8qPFuFJn4dZ7i76+kh94Yj77CfcUHb7tg=")
    }

    /// This simply tests that the generated signature matches that generated
    /// by the Python version of this plugin
    @Test func signingRequestGeneratesExpected() {
        let signingKey = headersBuilder().createSignatureKey()
        let stringToSign = """
        AWS4-HMAC-SHA256
        20250513T150921Z
        20250513/BAZ/s3/aws4_request
        aa65bce39a574dc0608936ec72db18263b6d9577768e2cdb363419129ef17673
        """
        let signature = HMAC<SHA256>.authenticationCode(
            for: Data(stringToSign.utf8),
            using: SymmetricKey(data: signingKey)
        ).compactMap { String(format: "%02x", $0) }.joined()
        #expect(signature == "f5c9ec461eb3690b56dce9870510d26745ef28234434915c2c4277834e5a2582")
    }
}
