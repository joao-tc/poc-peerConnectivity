//
//  LobbyView.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 05/11/25.
//

import SwiftUI
import MultipeerConnectivity

struct LobbyView: View {
    @ObservedObject private var session: TransportSession
    
    @State private var gameSession: GameSession?
    
    private let password: String
    
    @State private var gotoChat: Bool = false
    
    init(session: TransportSession, password: String) {
        self.session = session
        self.password = password
    }

    var body: some View {
        NavigationStack {
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
            .fullScreenCover(isPresented: Binding(get: { gameSession != nil }, set: { _ in })) {
                if let gs = gameSession {
                    GameView(session: gs)
                }
            }
        }
        .padding(16)
        .navigationDestination(isPresented: $gotoChat) {
//            ChatView(session: session)
        }
        .onAppear {
            session.setNotificationHandler(self)
        }
    }
}

extension LobbyView: MPCNotificationDelegate {
    func notify(_ notification: MPCNotifications) {
        switch notification {
        case .nextView:
            gotoChat = true
            
        case .gameConfig(let payload):
            self.gameSession = GameSession(transport: session, config: payload)
            
        default:
            break
        }
    }
}
