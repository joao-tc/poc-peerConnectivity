//
//  GameData.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 04/11/25.
//

import Foundation

public enum MPCMessage: Codable {
    case text(TextPayload)
    case game(GamePayload)
}

public struct TextPayload: Codable {
    public let message: String
    public let sender: String
}

public struct GamePayload: Codable {
    public let x: CGFloat
    public let y: CGFloat
}
