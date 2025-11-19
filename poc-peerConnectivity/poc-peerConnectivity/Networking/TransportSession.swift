//
//  TransportSession.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 11/11/25.
//

import Combine
import CryptoKit
import Foundation
import MultipeerConnectivity

// MARK: Main Class Declaration
public final class TransportSession: NSObject, ObservableObject,
    TransportSessionProtocol
{
    public var objectWillChange: ObservableObjectPublisher?

    // Peers
    public private(set) var myPeerID: MCPeerID
    public private(set) var connectedPeers: [MCPeerID] = []
    fileprivate var possiblePeers: [MCPeerID] = []

    // Session parameters
    fileprivate let serviceType = "poc"
    fileprivate var session: MCSession!
    fileprivate var advertiser: MCNearbyServiceAdvertiser?
    fileprivate var browser: MCNearbyServiceBrowser?
    fileprivate var textChatService: MPCTextChatService?
    fileprivate var notificationHandler: MPCNotificationDelegate?
    fileprivate var peerName: String

    // HMAC
    fileprivate var hostPassword: String?
    fileprivate var currentNonce: String?
    fileprivate var currentProof: String?
    fileprivate var discoveryInfoByPeer: [MCPeerID: [String: String]] = [:]

    // Callbacks
    public var onReceiveData: ((Data, MCPeerID) -> Void)?
    public var onPeerChange: (([MCPeerID]) -> Void)?

    // Initializer
    public init(userName: String) {
        let safeName = userName.isEmpty ? UIDevice.current.systemName : userName
        peerName = safeName
        myPeerID = MCPeerID(displayName: safeName)
        super.init()
        session = MCSession(
            peer: myPeerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        session.delegate = self
    }

    // Deinitializer
    deinit {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session.disconnect()
    }

    // Disconnect session
    public func disconnect() {
        session.disconnect()
    }
}

// MARK: Getters and Setters
extension TransportSession {

    // Notification Handler
    public func setNotificationHandler(_ handler: MPCNotificationDelegate) {
        self.notificationHandler = handler
    }

    // Possible peers
    public func getPossiblePeers() -> [MCPeerID] {
        possiblePeers
    }

    // Peer name
    public func getPeerName() -> String {
        peerName
    }

    // Set password
    public func setHostPassword(_ password: String) {
        hostPassword = password
    }
}

// MARK: - Sending Funcs
extension TransportSession {

    // Invites
    public func sendInvite(to peerID: MCPeerID) {
        browser?.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }

    public func invite(_ peer: MCPeerID, withPassword password: String) {
        if let info = discoveryInfoByPeer[peer],
            let nonce = info["nonce"],
            let expectedProof = info["proof"]
        {
            let computedProof = hmacSHA256Hex(key: password, message: nonce)

            if computedProof != expectedProof {
                return
            }
        }

        let data = try? JSONEncoder().encode(password)
        browser?.invitePeer(peer, to: session, withContext: data, timeout: 10)
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

    // Send data
    public func send(_ data: Data, reliably: Bool = true) throws {
        let mode: MCSessionSendDataMode = reliably ? .reliable : .unreliable
        try session.send(data, toPeers: session.connectedPeers, with: mode)
    }
}

// MARK: - Notification Funcs
extension TransportSession {
    public func notifyDelegate(_ notification: MPCNotifications) {
        notificationHandler?.notify(notification)
    }

    public func sendNotification(_ notification: MPCNotifications) {
        let payLoad = NotificationPayload(notification: notification)
        let message = MPCMessage.notification(payLoad)
        send(message: message)
        print("[\(peerName)] Sending notification: \(notification)")
    }
}

// MARK: - Advertising Funcs
extension TransportSession {

    // Start advertising with public nonce+proof for password authentication
    public func startAdvertising(withPassword password: String?) {
        print("[ADVERTISER] Started advertising...")
        print("[ADVERTISER] Device name: \(myPeerID.displayName)")
        print("[ADVERTISER] Service type: \(serviceType)")

        hostPassword = password
        let nonce = randomNonce()
        currentNonce = nonce
        currentProof = password.map { hmacSHA256Hex(key: $0, message: nonce) }

        let info: [String: String]? = {
            guard let nonce = currentNonce else { return nil }

            if let nonce = currentNonce, let proof = currentProof {
                return ["nonce": nonce, "proof": proof]
            }
            return ["nonce": nonce]
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

    // Stop advertising
    public func stopAdvertising() {
        print("[ADVERTISER] Stop advertising")
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
    }
}

// MARK: - Browsing funcs
extension TransportSession {

    // Start browsing
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

    // Stop browsing
    public func stopBrowsing() {
        print("[BROWSER] Stopping browser")
        browser?.stopBrowsingForPeers()
        browser = nil
        possiblePeers.removeAll()
        discoveryInfoByPeer.removeAll()
    }
}

// MARK: - Advertiser Delegate
extension TransportSession: MCNearbyServiceAdvertiserDelegate {

    // Received Invitation Callback
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
            print(
                "Host password: \(hostPassword ?? "nil"), Received password: \(receivedPassword ?? "nil")"
            )
            invitationHandler(false, nil)
        }
    }

    // Failed to Start Advertising
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
extension TransportSession: MCNearbyServiceBrowserDelegate {

    // Peer Found Callback
    public func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    ) {
        print("[BROWSER] Peer found: \(peerID.displayName)")
        possiblePeers.append(peerID)
        if let info = info { discoveryInfoByPeer[peerID] = info }
    }

    // Peer Lost Callback
    public func browser(
        _ browser: MCNearbyServiceBrowser,
        lostPeer peerID: MCPeerID
    ) {
        print("[BROWSER] Peer lost: \(peerID.displayName)")
        possiblePeers.removeAll { $0 == peerID }
        discoveryInfoByPeer.removeValue(forKey: peerID)
    }

    // Failed to Start Browsing
    public func browser(
        _ browser: MCNearbyServiceBrowser,
        didNotStartBrowsingForPeers error: any Error
    ) {
        print(
            "[BROWSER] Error trying to start browsing: \(error.localizedDescription)"
        )
    }
}

// MARK: - Session Delegate
extension TransportSession: MCSessionDelegate {

    // Peer Changed State
    public func session(
        _ session: MCSession,
        peer peerID: MCPeerID,
        didChange state: MCSessionState
    ) {
        print("[SESSION] Peer \(peerID.displayName) changed state")

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.connectedPeers = session.connectedPeers
            self.onPeerChange?(self.connectedPeers)

            switch state {
            case .connected:
                print("[SESSION] Connected to \(peerID.displayName)")
                print(
                    "[SESSION] Total peers connected: \(session.connectedPeers.count)"
                )
                self.notifyDelegate(.accepted)
            case .connecting:
                print("[SESSION] Connecting to \(peerID.displayName)...")
            case .notConnected:
                print("[SESSION] Unconnected from \(peerID.displayName)")
                print(
                    "[SESSION] Total peers connected: \(session.connectedPeers.count)"
                )

            default:
                print("[SESSION] Unknown")
                break
            }
        }
    }

    // Received Data
    public func session(
        _ session: MCSession,
        didReceive data: Data,
        fromPeer peerID: MCPeerID
    ) {
        if let message = try? JSONDecoder().decode(MPCMessage.self, from: data)
        {
            switch message {

                // Received a text message for the chat
            case .text(let payload):
                print("[\(peerID.displayName)] \(payload.message)")
                textChatService?.addMessage(
                    payload.message,
                    from: payload.sender
                )
                notifyDelegate(.refresh)

                // Received a horizontally moving parcel
            case .gameH(let payload):
                print(
                    "Parcel from \(peerID.displayName) going to the \(payload.side)"
                )
                notifyDelegate(.gameMove(payload))

                // Received a notification from other peer
            case .notification(let payload):
                print(
                    "[\(peerName)] Received notification: \(payload.notification)"
                )
                notifyDelegate(payload.notification)

                // Received the text chat service
            case .textChatService(let payload):
                print("[\(peerName)] Received the chat service")
                textChatService = payload.service

                // Received initial game configs
            case .gameConfig(let payload):
                print("[\(peerName)] Received game configs")
                notifyDelegate(.gameConfig(payload))
            default: break
            }
        } else {
            print("[\(peerName)] Failed to decode data")
        }
    }

    // Received InutStream
    public func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) {}

    // Started Receiving Resource
    public func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    ) {}

    // Finished Receiving Resource
    public func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: (any Error)?
    ) {}
}

// MARK: - CryptoKit
extension TransportSession {

    // Creates a HMAC
    fileprivate func hmacSHA256Hex(key: String, message: String) -> String {
        let keyData = Data(key.utf8)
        let msgData = Data(message.utf8)
        let hmac = HMAC<SHA256>.authenticationCode(
            for: msgData,
            using: SymmetricKey(data: keyData)
        )
        return hmac.map { String(format: "%02x", $0) }.joined()
    }

    // Creates a Random Nonce
    fileprivate func randomNonce(_ count: Int = 16) -> String {
        let chars =
            "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<count).compactMap { _ in chars.randomElement() })
    }
}
