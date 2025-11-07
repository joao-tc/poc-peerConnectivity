//
//  HostView.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 04/11/25.
//

import MultipeerConnectivity
import SwiftUI

struct HostView: View {

    @ObservedObject private var session: GameSession

    private var username: String

    public init(username: String) {
        self.username = username
        self.session = GameSession(username: username)
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
                    guard !session.connectedPeers.isEmpty else { return }
                    session.messageService = MPCMessageService(session: session)
                    print("Host tryied to add messageService to session. Result = \(session.messageService != nil)")
                    session.stopAdvertising()
                    session.sendNotification(.nextView)
                    gotoGame = true
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
//            session.disconnect()
            password = ""
        }
    }

    private func generatePassword(length: Int = 6) -> String {
        let charset = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<length).compactMap { _ in charset.randomElement() })
    }
}
