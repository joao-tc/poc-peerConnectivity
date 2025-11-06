//
//  JoinView.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 04/11/25.
//

import SwiftUI

struct JoinView: View {

    @ObservedObject private var session = GameSession()

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
                session.inviteResponseHandler = self
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

extension JoinView: MPCInviteResponseHandlerDelegate {
    
    func didReceiveInviteResponse(_ response: InviteResponse) {
        switch response {
        case .accepted:
            gotoLobby = true
        case .wrongPassword:
            errorMessage = "Wrong password"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                errorMessage = ""
            }
        }
    }
}
