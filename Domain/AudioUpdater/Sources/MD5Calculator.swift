//
//  MD5Calculator.swift
//
//
//  Created by Afifi, Mohamed on 8/16/20.
//

import CommonCrypto
import Foundation

struct MD5Calculator {
    func dataMD5(for url: URL) throws -> Data {
        let bufferSize = 1024 * 1024

        // Open file for reading:
        let file = try FileHandle(forReadingFrom: url)
        defer { file.closeFile() }

        // Create and initialize MD5 context:
        var context = CC_MD5_CTX()
        CC_MD5_Init(&context)

        // Read up to `bufferSize` bytes, until EOF is reached, and update MD5 context:
        while autoreleasepool(invoking: {
            let data = file.readData(ofLength: bufferSize)
            if !data.isEmpty {
                data.withUnsafeBytes {
                    _ = CC_MD5_Update(&context, $0.baseAddress, numericCast(data.count))
                }
                return true // Continue
            } else {
                return false // End of file
            }
        }) { }

        // Compute the MD5 digest:
        var digest: [UInt8] = Array(repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        _ = CC_MD5_Final(&digest, &context)

        return Data(digest)
    }

    func stringMD5(for url: URL) throws -> String {
        let data = try dataMD5(for: url)
        let hex = data.map { String(format: "%02hhx", $0) }.joined()
        return hex
    }
}
