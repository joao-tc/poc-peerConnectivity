//
//  GameSession.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 04/11/25.
//

import Combine
import Foundation
import MultipeerConnectivity
import SwiftUI
import UIKit
import CryptoKit

public final class GameSession: NSObject, ObservableObject {
    @Published public var connectedPeers = [MCPeerID]()
    @Published public var possiblePeers = [MCPeerID]()
    private var discoveryInfoByPeer: [MCPeerID: [String: String]] = [:]

    @Published public var hostPassword: String?

    private let serviceType = "test"
    private let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    //    private let myPeerID = MCPeerID(displayName: "Simulador")
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser?
    private var currentNonce: String?
    private var currentProof: String?
    private var browser: MCNearbyServiceBrowser?
    
    public var inviteResponseHandler: MPCInviteResponseHandlerDelegate?

    public override init() {
        super.init()
        session = MCSession(
            peer: myPeerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        session.delegate = self
    }

    // MARK: Advertising funcs
    public func startAdvertising() {
        print("[ADVERTISER] Started advertising...")
        print("[ADVERTISER] Device name: \(myPeerID.displayName)")
        print("[ADVERTISER] Service type: \(serviceType)")

        let nonce = randomNonce()
        currentNonce = nonce
        if let password = hostPassword {
            currentProof = hmacSHA256Hex(key: password, message: nonce)
        } else {
            currentProof = nil
        }
        
        let info: [String: String]? = {
            if let nonce = currentNonce, let proof = currentProof { return ["nonce": nonce, "proof": proof] }
            else if let nonce = currentNonce { return ["nonce": nonce] }
            else { return nil }
        }()
        
        
        advertiser = MCNearbyServiceAdvertiser(
            peer: myPeerID,
            discoveryInfo: info,
            serviceType: serviceType
        )
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()

        print("[ADVERTISER] Advertising started!")
    }

    public func stopAdvertising() {
        print("[ADVERTISER] Stop advertising")

        advertiser?.stopAdvertisingPeer()
    }

    // MARK: Browser funcs
    public func startBrowsing() {
        print("[BROWSER] Starting browser...")
        print("[BROWSER] Device name: \(myPeerID.displayName)")

        browser = MCNearbyServiceBrowser(
            peer: myPeerID,
            serviceType: serviceType
        )
        browser?.delegate = self
        browser?.startBrowsingForPeers()

        print("[BROWSER] Browsing started!")
    }

    public func stopBrowsing() {
        print("[BROWSER] Stoping browser")

        browser?.stopBrowsingForPeers()
    }

    
    // MARK: Other main funcs
    public func send(data: GameData) {
        guard !session.connectedPeers.isEmpty else { return }
        if let data = try? JSONEncoder().encode(data) {
            try? session.send(
                data,
                toPeers: session.connectedPeers,
                with: .reliable
            )
        }
    }

    public func setHostPassword(_ password: String) {
        hostPassword = password
        
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        startAdvertising()
    }
    
    public func disconnect() {
        session.disconnect()
    }
    
    public func sendInvite(to peerID: MCPeerID) {
        browser?.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }

    public func sendInvite(to peerID: MCPeerID, withPassword password: String) {
        if let info = discoveryInfoByPeer[peerID],
           let nonce = info["nonce"],
           let expectedProof = info["proof"] {
            let computedProof = hmacSHA256Hex(key: password, message: nonce)
            
            if computedProof != expectedProof {
                inviteResponseHandler?.didReceiveInviteResponse(.wrongPassword)
                return
            }
        }
        
        let data = try? JSONEncoder().encode(password)
        browser?.invitePeer(peerID, to: session, withContext: data, timeout: 10)
    }
}

// MARK: - Session Delegate
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
                self?.inviteResponseHandler?.didReceiveInviteResponse(.accepted)
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
        if let gameData = try? JSONDecoder().decode(GameData.self, from: data) {
            print("Received game data: \nX: \(gameData.x)   Y: \(gameData.y)")
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

// MARK: - Advertiser Delegate
extension GameSession: MCNearbyServiceAdvertiserDelegate {
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
            print("[ADVERTISER] ✅ Password correct. Accepting invite...")
            invitationHandler(true, session)
        } else {
            print("[ADVERTISER] ❌ Wrong password. Rejecting invite...")
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

// MARK: - Browser Delegate
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

// MARK: - Invite Response Delegate
public protocol MPCInviteResponseHandlerDelegate {
    func didReceiveInviteResponse(_ response: InviteResponse) -> Void
}

// MARK: - Invite Reopnse Enum
public enum InviteResponse {
    case wrongPassword
    case accepted
}

// MARK: - Crypto
extension GameSession {
    
    private func hmacSHA256Hex(key: String, message: String) -> String {
        let keyData = Data(key.utf8)
        let msgData = Data(message.utf8)
        let hmac = HMAC<SHA256>.authenticationCode(for: msgData, using: SymmetricKey(data: keyData))
        return hmac.map { String(format: "%02x", $0) }.joined()
    }
    
    private func randomNonce(_ count: Int = 16) -> String {
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<count).compactMap { _ in chars.randomElement() })
    }
}
