//
//  MPCConnection+AdvertiserDelegate.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 06/11/25.
//

import Foundation
import MultipeerConnectivity

extension MPCConnection: MCNearbyServiceAdvertiserDelegate {
    
    public func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        print("[ADVERTISER] Invite received from: \(peerID.displayName)")
        var receivedPassword: String? = nil
        if let context = context {
            receivedPassword = try? JSONDecoder().decode(
                String.self,
                from: context
            )
        }

        if let hostPassword = hostPassword, hostPassword == receivedPassword {
            print("[ADVERTISER] Password correct. Accepting invite...")
            invitationHandler(true, session)
        } else {
            print("[ADVERTISER] Wrong password. Rejecting invite...")
            print("Host password: \(hostPassword ?? "nil"), Received password: \(receivedPassword ?? "nil")")
            invitationHandler(false, nil)
        }
    }
    
    public func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didNotStartAdvertisingPeer error: any Error
    ) {
        print(
            "[ADVERTISER] Error to start advertising: \(error.localizedDescription)"
        )
    }
}
