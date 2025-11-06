//
//  GameSession+Crypto.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 06/11/25.
//

import Foundation
import CryptoKit

extension GameSession {
    internal func hmacSHA256Hex(key: String, message: String) -> String {
        let keyData = Data(key.utf8)
        let msgData = Data(message.utf8)
        let hmac = HMAC<SHA256>.authenticationCode(for: msgData, using: SymmetricKey(data: keyData))
        return hmac.map { String(format: "%02x", $0) }.joined()
    }
    
    internal func randomNonce(_ count: Int = 16) -> String {
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<count).compactMap { _ in chars.randomElement() })
    }
}
