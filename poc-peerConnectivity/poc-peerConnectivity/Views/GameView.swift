//
//  GameView.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 06/11/25.
//

import SwiftUI

struct GameView: View {

    @ObservedObject private var session: GameSession

    public init(session: GameSession) {
        self.session = session
    }
    
    @State private var currentMessage: String = ""

    var body: some View {

        VStack {
            Text("IN GAME")
                .font(.largeTitle)

            ForEach(session.messageService?.getMessages() ?? [], id: \.self) {
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
            }
        }
    }
}
