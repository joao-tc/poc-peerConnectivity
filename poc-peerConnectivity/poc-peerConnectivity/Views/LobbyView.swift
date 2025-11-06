//
//  LobbyView.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 05/11/25.
//

import SwiftUI
import MultipeerConnectivity

struct LobbyView: View {
    @ObservedObject private var session: GameSession
    
    init(session: GameSession) {
        self.session = session
    }

    private let password: String = String("\(UUID())".prefix(6))

    var body: some View {
        VStack {
            Text("Game Lobby")
                .font(.title2)
            Text("Waiting for host to start the game")

            Spacer()
            
            Text("The password is:")
            Text(password)
                .font(.largeTitle)

            Spacer()

            VStack {
                Text("Connected peers")
                ForEach(session.connectedPeers, id: \.self) { peer in
                    Text(peer.displayName)
                }
            }
            
            Spacer()
            Spacer()
            Spacer()
        }
        .padding(16)
        .onDisappear {
            session.disconnect()
        }
    }
}
