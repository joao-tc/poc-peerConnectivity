//
//  AssignRoleView.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 18/11/25.
//

import MultipeerConnectivity
import SwiftUI

struct AssignRoleView: View {

    @ObservedObject private var transport: TransportSession
    @State private var assignedRoles: [MCPeerID: StationRole] = [:]
    @State private var gameSession: GameSession?

    @State private var startGame: Bool = false

    public init(transport: TransportSession) {
        self.transport = transport
    }

    var body: some View {
        NavigationStack {
            Text("Assign role")
                .font(.title)

            List {
                ForEach(transport.connectedPeers, id: \.self) { peer in
                    HStack {
                        Text(peer.displayName)
                        Spacer()
                        Menu(assignedRoles[peer]?.displayName ?? "Select role")
                        {
                            ForEach(StationRole.allCases, id: \.self) { role in
                                if role != .chef {
                                    Button(role.displayName) {
                                        assign(role, to: peer)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Button("Start Game") {
                startGameIfReady()
            }
            .fullScreenCover(
                isPresented: Binding(get: { gameSession != nil }, set: { _ in })
            ) {
                if let gameSession = gameSession {
                    GameView(session: gameSession)
                }
            }
        }
        .onAppear {
            assignedRoles[transport.myPeerID] = .chef
        }
    }

    private var canStart: Bool {
        let peers = transport.connectedPeers
        let requiredPlayers = 2
        let requiredPeers = requiredPlayers - 1

        let cond1 = peers.count == requiredPeers
        if !cond1 { print("failed condition 1") }

        let cond2 = assignedRoles.count == requiredPlayers
        if !cond2 {
            print("failed condition 2")

            print(assignedRoles)
        }

        let cond3 = Set(assignedRoles.values).count == requiredPlayers
        if !cond3 {
            print("failed condition 3")
            print(assignedRoles)
        }

        return cond1 && cond2 && cond3
    }

    private func assign(_ role: StationRole, to peer: MCPeerID) {
        for (p, r) in assignedRoles where r == role && p != peer {
            assignedRoles[p] = nil
        }
        assignedRoles[peer] = role
    }

    private func startGameIfReady() {
        guard canStart else {
            print("Can't start")
            return
        }

        let playerIDs =
            [transport.myPeerID.displayName]
            + transport.connectedPeers.map(\.displayName)
        let rolesByID = assignedRoles.reduce(into: [String: StationRole]()) {
            dict,
            pair in
            dict[pair.key.displayName] = pair.value
        }

        let payload = GameConfigPayload(
            mode: .classic,
            players: playerIDs,
            roles: rolesByID
        )

        let message = MPCMessage.gameConfig(payload)
        transport.send(message: message)

        print("Initializing gameSession on host, should start the game")
        gameSession = GameSession(
            transport: transport,
            config: payload
        )
    }
}
