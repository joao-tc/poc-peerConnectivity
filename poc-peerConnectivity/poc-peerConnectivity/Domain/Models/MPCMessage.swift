//
//  GameData.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 04/11/25.
//

import Foundation

public enum MPCMessage: Codable {
    case text(TextPayload)
    case gameH(GamePayload)
    case gameV(GamePayload)
    case notification(NotificationPayLoad)
    case textChatService(TextChatServicePayload)
}

public struct TextPayload: Codable {
    public let message: String
    public let sender: String
}

public struct GamePayload: Codable {
    public let x: CGFloat
    public let y: CGFloat
    public var side: EdgeSide = .none
    public var ingredientType: IngredientType = .genericParcel
    public var ingredientState: IngredientState = .base
}

public struct NotificationPayLoad: Codable {
    public let notification: MPCNotifications
}

public struct TextChatServicePayload: Codable {
    public let service: MPCTextChatService
}
