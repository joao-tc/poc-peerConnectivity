//
//  MPCInviteResponseHandlerDelegate.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 06/11/25.
//

import Foundation

public protocol MPCInviteResponseHandlerDelegate {
    func didReceiveInviteResponse(_ response: InviteResponse) -> Void
}
