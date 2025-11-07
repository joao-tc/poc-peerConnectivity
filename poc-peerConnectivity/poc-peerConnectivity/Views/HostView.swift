//
//  HostView.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 04/11/25.
//

import MultipeerConnectivity
import SwiftUI

struct HostView: View {

    @StateObject private var session: GameSession

    private var username: String

    public init(username: String) {
        self.username = username
        _session = StateObject(wrappedValue: GameSession(username: username))
    }

    @State private var password: String = ""
    @State private var gotoGame: Bool = false

    var body: some View {
        NavigationStack {
            VStack {
                Text("Hosting Game")
                    .font(.title2)

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

                Button("Start game") {
                    startGame()
                }
            }
        }
        .padding(16)
        .navigationDestination(isPresented: $gotoGame) {
            GameView(session: session)
        }
        .onAppear {
            password = generatePassword()
            session.setHostPassword(password)
            session.startAdvertising()
        }
        .onDisappear {
            session.stopAdvertising()
            password = ""
        }
    }
    
    private func startGame() {
        guard !session.connectedPeers.isEmpty else { return }
        let textChatService = MPCTextChatService()
        session.textChatService = textChatService
        print("Host tryied to add textChatService to session. Result = \(session.textChatService != nil)")
        
        let payload = TextChatServicePayload(service: textChatService)
        let message = MPCMessage.textChatService(payload)
        session.send(message: message)
        session.stopAdvertising()
        session.sendNotification(.nextView)
        gotoGame = true
    }

    private func generatePassword(length: Int = 6) -> String {
        let charset = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<length).compactMap { _ in charset.randomElement() })
    }
}
