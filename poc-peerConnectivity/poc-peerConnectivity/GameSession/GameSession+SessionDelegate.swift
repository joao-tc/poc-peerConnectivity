//
//  GameSession+SessionDelegate.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 06/11/25.
//

import Foundation
import MultipeerConnectivity

extension GameSession: MCSessionDelegate {

    // Peer changed state
    public func session(
        _ session: MCSession,
        peer peerID: MCPeerID,
        didChange state: MCSessionState
    ) {
        print("[SESSION] Peer \(peerID.displayName) changed state")

        DispatchQueue.main.async { [weak self] in
            self?.connectedPeers = session.connectedPeers

            switch state {
            case .connected:
                print("[SESSION] Connected to \(peerID.displayName)")
                print("[SESSION] Total peers connected: \(session.connectedPeers.count)")
                self?.responsiveHandler?.notify(.accepted)
            case .connecting:
                print("[SESSION] Connecting to \(peerID.displayName)...")
            case .notConnected:
                print("[SESSION] Unconnected from \(peerID.displayName)")
                print(
                    "[SESSION] Total de peers connected: \(session.connectedPeers.count)"
                )

            @unknown default:
                print("[SESSION] Unknown")
                break
            }
        }
    }

    // Received data
    public func session(
        _ session: MCSession,
        didReceive data: Data,
        fromPeer peerID: MCPeerID
    ) {
        print("[\(getPeerName())] Received data, trying to decode...")
        if let message = try? JSONDecoder().decode(MPCMessage.self, from: data) {
            switch(message) {
            case .text(let text):
                print("[\(peerID)] \(text)")
            
            case .game(let game):
                print("[\(peerID)] X: \(game.x) Y: \(game.y)")
                
            case .notification(let not):
                print("[\(getPeerName())] Received notification: \(not.notification)")
//                guard seenNotifications.contains(not.id) else { return }
//                seenNotifications.insert(not.id)
                
                notifyDelegate(not.notification)
            }
        } else {
            print("[\(getPeerName())] Failed to decode data")
        }
    }

    public func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) {}
    public func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    ) {}
    public func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: (any Error)?
    ) {}
}
