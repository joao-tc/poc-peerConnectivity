//
//  GameSession+BrowserDelegate.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 06/11/25.
//

import Foundation
import MultipeerConnectivity

extension GameSession: MCNearbyServiceBrowserDelegate {
    public func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    ) {
        print("[BROWSER] Peer found: \(peerID.displayName)")
        possiblePeers.append(peerID)
        if let info = info { discoveryInfoByPeer[peerID] = info }
    }

    public func browser(
        _ browser: MCNearbyServiceBrowser,
        lostPeer peerID: MCPeerID
    ) {
        print("[BROWSER] Peer lost: \(peerID.displayName)")
        possiblePeers.removeAll { $0 == peerID }
        discoveryInfoByPeer.removeValue(forKey: peerID)
    }
    
    public func browser(
        _ browser: MCNearbyServiceBrowser,
        didNotStartBrowsingForPeers error: any Error
    ) {
        print(
            "[BROWSER] Error trying to start browsing: \(error.localizedDescription)"
        )
    }
}
