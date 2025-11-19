//
//  MessageService.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 06/11/25.
//

import Foundation
import Combine

public final class MPCTextChatService: Codable {
    
    private var messages: [TextPayload] = []
    
    public func getMessages() -> [String] {
        messages.compactMap { "[\($0.sender)] \($0.message)" }
    }
    
    public func addMessage(_ message: String, from sender: String) {
        messages.append(TextPayload(message: message, sender: sender))
    }
}
