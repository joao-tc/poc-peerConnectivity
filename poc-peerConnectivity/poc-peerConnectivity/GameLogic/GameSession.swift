//
//  GameSession.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 14/11/25.
//

import Foundation
import MultipeerConnectivity
import Combine

// Different game modes
public enum GameMode: String, Codable, Equatable {
    case classic
    case chaos
}

// Represents a part of the screen - used to send parcels via MP
public enum EdgeSide: String, Codable {
    case left
    case right
    case none
}

// Incapsulates the player name - used to transport IDs instead of MCPeerID instances
public struct PlayerID: Hashable, Codable {
    let rawValue: String
}


public final class GameSession: ObservableObject {
    
    // Transport layer
    private let transport: TransportSession
    
    // Current game mode
    private let gameMode: GameMode

    // Connected players and their roles
    private let players: [PlayerID]
    @Published private(set) var roles: [PlayerID: StationRole]
    
    
    public var myID: PlayerID {
        PlayerID(rawValue: transport.myPeerID.displayName)
    }
    
    public var myRole: StationRole {
        roles[myID] ?? .notSet
    }
    
    private var chefID: PlayerID? {
        roles.first(where: { $0.value == .chef })?.key
    }
    
    private var amIChef: Bool {
        chefID == myID
    }
    
    // Initializer
    public init(transport: TransportSession, config: GameConfigPayload) {
        self.transport = transport
        self.gameMode = config.mode
        self.players = config.players.map { PlayerID(rawValue: $0) }
        self.roles = config.roles.reduce(into: [PlayerID: StationRole]()) { dict, pair in
            dict[PlayerID(rawValue: pair.key)] = pair.value
        }
    }
    
    // Sends a Ingredient to the chef - used on classic mode
    public func sendIngredientToChef(_ ingredient: Ingredient) {
        let x: CGFloat = CGFloat.random(in: -200...200)
        let y: CGFloat = -200
        
        let payload = GamePayload(x: x, y: y, ingredientType: ingredient.type, ingredientState: ingredient.state)
        
        let message = MPCMessage.gameV(payload)
        transport.send(message: message)
    }
    
    // Used to get the 'neighboor' - on classic mode, always returns the chefID
    public func destinationForToss(from side: EdgeSide) -> PlayerID? {
        switch gameMode {
        case .classic:
            return chefID
        
        case .chaos:
            // TODO: topography
            return chefID
        }
    }
}


// MARK: - Transmission layer masking
extension GameSession {
    
    // Exposes notification delegate from the transport layer
    public func setNotificationHandler(_ handler: MPCNotificationDelegate) {
        transport.setNotificationHandler(handler)
    }
    
    // Exposes specific use of the send(message) function
    public func sendParcelHorizontally(_ payload: GamePayload) {
        let message = MPCMessage.gameH(payload)
        transport.send(message: message)
    }
}
