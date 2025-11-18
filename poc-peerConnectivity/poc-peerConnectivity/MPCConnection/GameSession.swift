//
//  GameSession.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 14/11/25.
//

import Foundation
import MultipeerConnectivity
import Combine

public enum GameMode: Codable {
    case classic
    case chaos
}

public struct PlayerID: Hashable, Codable {
    let rawValue: String
}

public final class GameSession: ObservableObject {
    public var objectWillChange: ObservableObjectPublisher?
    
    private let transport: TransportSession
    private let gameMode: GameMode

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
    
    public init(transport: TransportSession, config: GameConfigPayload) {
        self.transport = transport
        self.gameMode = config.mode
        self.players = config.players.map { PlayerID(rawValue: $0) }
        self.roles = config.roles.reduce(into: [PlayerID: StationRole]()) { dict, pair in
            dict[PlayerID(rawValue: pair.key)] = pair.value
        }
    }
    
    public func sendIngredientToChef(_ ingredient: Ingredient) {
        let x: CGFloat = CGFloat.random(in: -200...200)
        let y: CGFloat = -200
        
        let payload = GamePayload(x: x, y: y, ingredientType: ingredient.type, ingredientState: ingredient.state)
        
        let message = MPCMessage.gameV(payload)
        transport.send(message: message)
    }
    
    public func destinationForToss(from side: EdgeSide) -> PlayerID? {
        if gameMode == .classic {
            return chefID
        }
        return chefID
    }
}


// MARK: - Transmission layer masking
extension GameSession {
    
    public func setNotificationHandler(_ handler: MPCNotificationDelegate) {
        transport.setNotificationHandler(handler)
    }
    
    public func sendParcelHorizontally(_ payload: GamePayload) {
        let message = MPCMessage.gameH(payload)
        transport.send(message: message)
    }
}
