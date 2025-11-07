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
    
    private let password: String
    
    @State private var gotoChat: Bool = false
    @State private var gotoGame: Bool = false
    
    init(session: GameSession, password: String) {
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
        }
        .padding(16)
        .navigationDestination(isPresented: $gotoChat) {
            ChatView(session: session)
        }
        .navigationDestination(isPresented: $gotoGame) {
            GameView(session: session)
        }
        .onAppear {
            session.notificationHandler = self
        }
    }
}

extension LobbyView: MPCNotificationDelegate {
    func notify(_ notification: MPCNotifications) {
        switch(notification) {
        case .nextView:
            gotoChat = true
            
        case .nextView2:
            gotoGame = true
            
        default:
            break
        }
    }
}
