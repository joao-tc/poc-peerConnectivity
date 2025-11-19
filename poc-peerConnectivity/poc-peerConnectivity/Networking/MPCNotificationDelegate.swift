//
//  MPCInviteResponseHandlerDelegate.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 06/11/25.
//

import Foundation

// Used to add reactivity to the app
public protocol MPCNotificationDelegate {
    func notify(_ notification: MPCNotifications) -> Void
}
