//
//  MPCConnection.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 04/11/25.
//

import Combine
import Foundation
import MultipeerConnectivity
import SwiftUI
import UIKit

public final class MPCConnection: NSObject, ObservableObject {
    
    // Peers
    @Published public var connectedPeers = [MCPeerID]()
    @Published public var possiblePeers = [MCPeerID]()
    var discoveryInfoByPeer: [MCPeerID: [String: String]] = [:]

    // Password
    @Published public var hostPassword: String?

    // Peer info
    private let myPeerID: MCPeerID
    public func getPeerName() -> String { return myPeerID.displayName }
    
    // Session info
    private let serviceType = "test"
    var session: MCSession!
    
    // Advertiser
    private var advertiser: MCNearbyServiceAdvertiser?
    private var currentNonce: String?
    private var currentProof: String?
    
    // Browser
    private var browser: MCNearbyServiceBrowser?

    // Services and handlers
    public var notificationHandler: MPCNotificationDelegate?
    public var textChatService: MPCTextChatService?
    
    
    public init(username: String) {
        var safeName = ""
        safeName = username.isEmpty ? UIDevice.current.name : username
        myPeerID = MCPeerID(displayName: safeName)
        super.init()
        session = MCSession(
            peer: myPeerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        session.delegate = self
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
}


// MARK: - Sending funcs
extension MPCConnection {
    // Invites
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
                return
            }
        }
        
        let data = try? JSONEncoder().encode(password)
        browser?.invitePeer(peerID, to: session, withContext: data, timeout: 10)
    }
    
    // Send generic message type
    public func send(message data: MPCMessage) {
        guard !session.connectedPeers.isEmpty else { return }
        if let data = try? JSONEncoder().encode(data) {
            try? session.send(
                data,
                toPeers: session.connectedPeers,
                with: .reliable
            )
        }
    }
    
    // Send text message
    public func send(text: String, from user: String) {
        print("[\(user)] Trying to send text message: \(text)")
        print("Current session has messageService? \(textChatService != nil)")
        
        textChatService?.addMessage(text, from: user)
        
        let payload = TextPayload(message: text, sender: user)
        let message = MPCMessage.text(payload)
        send(message: message)
    }
}


// MARK: - NNotification funcs
extension MPCConnection {
    public func notifyDelegate(_ notification: MPCNotifications) {
        notificationHandler?.notify(notification)
    }
    
    public func sendNotification(_ notification: MPCNotifications) {
        let payLoad = NotificationPayLoad(notification: notification)
        let message = MPCMessage.notification(payLoad)
        send(message: message)
        print("[\(getPeerName())] Sending notification: \(notification)")
    }
}


// MARK: - Browser funcs
extension MPCConnection {
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
extension MPCConnection {
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
