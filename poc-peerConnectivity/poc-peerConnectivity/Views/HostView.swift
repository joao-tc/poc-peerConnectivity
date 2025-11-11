//
//  HostView.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 04/11/25.
//

import MultipeerConnectivity
import SwiftUI

struct HostView: View {

    @StateObject private var session: MPCConnection

    private var username: String

    public init(username: String) {
        self.username = username
        _session = StateObject(wrappedValue: MPCConnection(username: username))
    }

    @State private var password: String = ""
    @State private var gotoChat: Bool = false
    @State private var gotoGame: Bool = false

    var body: some View {
        NavigationStack {
            VStack {
                Text("Hosting Session")
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

                Button("Start chat") {
                    startChat()
                }
                .buttonStyle(.borderedProminent)
                .frame(width: .infinity)
                
                Button("Start game") {
                    startGame()
                }
                .buttonStyle(.borderedProminent)
                .frame(width: .infinity)
            }
        }
        .padding(16)
        .navigationDestination(isPresented: $gotoChat) {
            ChatView(session: session)
        }
        .fullScreenCover(isPresented: $gotoGame) {
            GameView(session: session)
        }
        .onAppear {
            password = generatePassword(length: 6)
            session.setHostPassword(password)
            session.startAdvertising()
        }
        .onDisappear {
            session.stopAdvertising()
            password = ""
        }
    }
    
    private func startChat() {
        guard !session.connectedPeers.isEmpty else { return }
        let textChatService = MPCTextChatService()
        session.textChatService = textChatService
//        print("Host tryied to add textChatService to session. Result = \(session.textChatService != nil)")
        
        let payload = TextChatServicePayload(service: textChatService)
        let message = MPCMessage.textChatService(payload)
        session.send(message: message)
        session.stopAdvertising()
        session.sendNotification(.nextView)
        gotoChat = true
    }
    
    private func startGame() {
        guard !session.connectedPeers.isEmpty else { return }
        
        session.stopAdvertising()
        session.sendNotification(.nextView2)
        gotoGame = true
    }

    private func generatePassword(length: Int = 6) -> String {
        let charset = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<length).compactMap { _ in charset.randomElement() })
    }
}
