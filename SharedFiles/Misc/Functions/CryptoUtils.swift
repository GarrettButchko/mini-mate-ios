//
//  CryptoUtils.swift
//  MiniMate
//
//  Created by GitHub Copilot on 2026-03-13.
//

import Foundation
import CryptoKit

/// Generates a random alphanumeric nonce of the given length.
func randomNonceString(length: Int = 32) -> String {
    guard length > 0 else {
        print("❌ Invalid length: \(length), using default 32")
        return randomNonceString(length: 32)
    }
    let charset: [Character] =
    Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length
    
    while remainingLength > 0 {
        // 16 bytes at a time
        let randoms = (0..<16).map { _ in UInt8.random(in: 0...255) }
        randoms.forEach { byte in
            if remainingLength == 0 { return }
            if byte < charset.count {
                result.append(charset[Int(byte)])
                remainingLength -= 1
            }
        }
    }
    
    return result
}

/// Hashes input with SHA256 and returns the hex string.
func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashed = SHA256.hash(data: inputData)
    return hashed.compactMap { String(format: "%02x", $0) }.joined()
}
