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
                self?.notifyDelegate(.accepted)
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
//        print("[\(getPeerName())] Received data, trying to decode...")
        if let message = try? JSONDecoder().decode(MPCMessage.self, from: data) {
            switch(message) {
            case .text(let payload):
                print("[\(peerID.displayName)] \(payload.message)")
                textChatService?.addMessage(payload.message, from: payload.sender)
                notifyDelegate(.refresh)
            
            case .game(let payload):
                print("[\(peerID.displayName)] X: \(payload.x) Y: \(payload.y)")
                notifyDelegate(.gameMove(payload))
                
            case .notification(let payload):
                print("[\(getPeerName())] Received notification: \(payload.notification)")
                notifyDelegate(payload.notification)
                
            case .textChatService(let payload):
                print("[\(getPeerName())] Received the chat service")
                textChatService = payload.service
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
