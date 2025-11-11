//
//  TransportSession.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 11/11/25.
//

import Foundation
import MultipeerConnectivity

public final class TransportSession: NSObject, Transporting {
    public private(set) var myPeerID: MCPeerID
    public private(set) var connectedPeers: [MCPeerID]
    
    private let serviceType = "poc"
    private var session: MCSession!
    private var advertise: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    // HMAC
    private var currentNonce: String?
    private var currentProff: String?
    private var discoveryInfoByPeer: [MCPeerID: [String: String]] = [:]
    
    public var onReceiveData: ((Data, MCPeerID) -> Void)?
    public var onPeerChange: (([MCPeerID]) -> Void)?
    
    public init(userName: String) {
        let safeName = userName.isEmpty ? UIDevice.current.systemName : userName
        myPeerID = MCPeerID(displayName: safeName)
        super.init()
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
    }
    
    public func startAdvertising(withPassword password: String?) {
        <#code#>
    }
    
    public func stopAdvertising() {
        <#code#>
    }
    
    public func startBrowsing() {
        <#code#>
    }
    
    public func stopBrowsing() {
        <#code#>
    }
    
    public func invite(_ peer: MCPeerID, withPassword password: String?) {
        <#code#>
    }
    
    public func disconnect() {
        <#code#>
    }
    
    public func send(_ data: Data, reiably: Bool) throws {
        <#code#>
    }
}
