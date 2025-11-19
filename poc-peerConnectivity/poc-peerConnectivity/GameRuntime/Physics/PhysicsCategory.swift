//
//  PhysicsCategory.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 10/11/25.
//

import Foundation

public struct PhysicsCategory {
    static let edge: UInt32 = 1 << 0
    static let parcel: UInt32 = 1 << 1
    static let sensorRight: UInt32 = 1 << 2
    static let sensorLeft: UInt32 = 1 << 3
    static let obstacle: UInt32 = 1 << 4
}
