//
//  InviteResponse.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 06/11/25.
//

import Foundation

// Different types of notification
public enum MPCNotifications: Codable {
    case nextView
    case nextView2
    case previousView
    case wrongPassword
    case accepted
    case refresh
    case gameMove(GamePayload)
    case gameConfig(GameConfigPayload)
}
