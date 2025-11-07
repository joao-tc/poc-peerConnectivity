//
//  GameView.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 06/11/25.
//

import SwiftUI

struct ChatView: View {

    @ObservedObject private var session: GameSession

    public init(session: GameSession) {
        self.session = session
    }
    
    @State private var currentMessage: String = ""
    
    @State private var refreshID = UUID()

    var body: some View {

        VStack {
            Text("IN GAME")
                .font(.largeTitle)

            ForEach(session.textChatService?.getMessages() ?? [], id: \.self) {
                message in
                Text(message)
                    .font(.body)
            }

            VStack {
                Text("Chat with your friends!")
                
                HStack {
                    TextField("Write here", text: $currentMessage)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Send") {
                        session.send(text: currentMessage, from: session.getPeerName())
                        currentMessage = ""
                    }
                }
                .padding(16)
            }
        }
        .padding(16)
        .onAppear {
            session.notificationHandler = self
        }
        .id(refreshID)
    }
}

extension ChatView: MPCNotificationDelegate {
    func notify(_ notification: MPCNotifications) {
        switch(notification) {
        case .refresh:
            refreshID = UUID()
            
        default: break
        }
    }
}
