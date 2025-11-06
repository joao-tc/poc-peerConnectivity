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

public final class GameSession: NSObject, ObservableObject {
    @Published public var connectedPeers = [MCPeerID]()
    @Published public var possiblePeers = [MCPeerID]()
    internal var discoveryInfoByPeer: [MCPeerID: [String: String]] = [:]

    @Published public var hostPassword: String?

    private let serviceType = "test"
    private let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    internal var session: MCSession!
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
            let expectedProof = info["proof"]
        {
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


// MARK: - Browser funcs
extension GameSession {
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
}


// MARK: - Advertising funcs
extension GameSession {
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
            if let nonce = currentNonce, let proof = currentProof {
                return ["nonce": nonce, "proof": proof]
            } else if let nonce = currentNonce {
                return ["nonce": nonce]
            } else {
                return nil
            }
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
}
