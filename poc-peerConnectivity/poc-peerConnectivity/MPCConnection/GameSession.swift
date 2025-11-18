//
//  GameSession.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 14/11/25.
//

import Foundation
import MultipeerConnectivity
import Combine

public enum GameMode {
    case classic
    case chaos
}

public final class GameSession: ObservableObject {
    public var objectWillChange: ObservableObjectPublisher?
    
    private let transport: TransportSession
    
    private let players: [MCPeerID]
    
    private let gameMode: GameMode = .classic
    
    @Published private(set) var roles: [MCPeerID: StationRole]
    
    private var chefPeer: MCPeerID? {
        roles.first(where: { $0.value == .chef })?.key
    }
    
    private var amIChef: Bool {
        guard let chefPeer = chefPeer else { return false }
        
        return chefPeer == transport.myPeerID
    }
    
    public init(transport: TransportSession, players: [MCPeerID], roles: [MCPeerID: StationRole]) {
        precondition(players.count == 4, "Phase 1 requires exactly 4 players")
        precondition(Set(roles.values).count == 4, "Each role must be used exactly once")
        
        self.transport = transport
        self.players = players
        self.roles = roles
        
        transport.setNotificationHandler(self)
    }
    
    func sendIngredientToChef(_ ingredient: Ingredient) {
        guard chefPeer != nil else { return }
        
        let x: CGFloat = CGFloat.random(in: -200...200)
        let y: CGFloat = -200
        
        let payload = GamePayload(x: x, y: y, ingredientType: ingredient.type, ingredientState: ingredient.state)
        
        let message = MPCMessage.gameV(payload)
        transport.send(message: message)
    }
}


// MARK: - Notification Delegate
extension GameSession: MPCNotificationDelegate {
    public func notify(_ notification: MPCNotifications) {
        
        switch notification {
            
        case .gameMove(let payload):
            if amIChef {
                print("[GAMESESSION] Chef received ingredient: ", payload.ingredientType)
            }
            
            
        default: break
        }
    }
}
