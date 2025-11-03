//
//  PeerService.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 03/11/25.
//

import Foundation
import MultipeerConnectivity
internal import Combine

/// Tiny wrapper around MultipeerConnectivity for auto host/guest discovery/connection.
final class PeerService: NSObject, ObservableObject {
    @Published var connectedPeers: [MCPeerID] = []

    // 1–15 lowercase letters & numbers only
    private let serviceType = "edge-pass"

    private let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    private lazy var session: MCSession = {
        let s = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        s.delegate = self
        return s
    }()

    private lazy var advertiser = MCNearbyServiceAdvertiser(
        peer: myPeerID,
        discoveryInfo: nil,
        serviceType: serviceType
    )

    private lazy var browser = MCNearbyServiceBrowser(
        peer: myPeerID,
        serviceType: serviceType
    )

    override init() {
        super.init()
        advertiser.delegate = self
        browser.delegate = self
    }

    /// Start looking for peers and advertising ourselves.
    func start() {
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }

    /// Stop all discovery/advertising (optional for POC).
    func stop() {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        session.disconnect()
        connectedPeers.removeAll()
    }
}

// MARK: - MCSessionDelegate
extension PeerService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.connectedPeers = session.connectedPeers
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) { /* not used yet */ }
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}

    /// Auto-trust for the POC (OK for local tests; consider a UI prompt in production).
    func session(_ session: MCSession, didReceiveCertificate cert: [Any]?, fromPeer peerID: MCPeerID,
                 certificateHandler: @escaping (Bool) -> Void) {
        certificateHandler(true)
    }
}

// MARK: - Advertiser
extension PeerService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session) // auto-accept
    }
}

// MARK: - Browser
extension PeerService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) { }
}
