//
//  Transporting.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 11/11/25.
//

import Foundation
import MultipeerConnectivity

public protocol Transporting: AnyObject {
    var myPeerID: MCPeerID { get }
    var connectedPeers: [MCPeerID] { get }
    
    func startAdvertising(withPassword password: String?)
    func stopAdvertising()
    
    func startBrowsing()
    func stopBrowsing()
    
    func invite(_ peer: MCPeerID, withPassword password: String?)
    func disconnect()
    
    func send(_ data: Data, reiably: Bool) throws
    
    var onReceiveData: ((Data, MCPeerID) -> Void)? { get set }
    var onPeerChange: (([MCPeerID]) -> Void)? { get set }
}
