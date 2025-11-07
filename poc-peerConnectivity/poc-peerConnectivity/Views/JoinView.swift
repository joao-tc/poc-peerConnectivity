//
//  JoinView.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 04/11/25.
//

import SwiftUI

struct JoinView: View {

    @StateObject private var session: GameSession

    private var username: String

    public init(username: String) {
        self.username = username
        _session = StateObject(wrappedValue: GameSession(username: username))
    }

    @State private var password: String = ""

    @State private var errorMessage: String = ""

    @State private var gotoLobby: Bool = false

    var body: some View {

        NavigationStack {
            VStack {
                Text("Join game")
                    .font(.title2)

                HStack {
                    TextField("passowrd", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.characters)

                    Spacer()

                    Button("Join") {
                        guard !password.isEmpty else { return }
                        tryToJoin(withPassword: password)
                    }
                    .buttonStyle(.automatic)
                }
                .padding(16)

                Text(errorMessage)

                Spacer()
            }
            .padding(16)
            .onAppear {
                session.notificationHandler = self
                session.startBrowsing()
                password = ""
            }
            .onDisappear {
                session.stopBrowsing()
            }
        }
        .navigationDestination(isPresented: $gotoLobby) {
            LobbyView(session: session, password: password)
        }
    }

    private func tryToJoin(withPassword password: String) {
        for peer in session.possiblePeers {
            session.sendInvite(to: peer, withPassword: password)
        }
    }
}

extension JoinView: MPCNotificationDelegate {
    func notify(_ response: MPCNotifications) {
        switch response {
        case .accepted:
            gotoLobby = true
        case .wrongPassword:
            errorMessage = "Wrong password"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                errorMessage = ""
            }
        default:
            break
        }
    }
}
