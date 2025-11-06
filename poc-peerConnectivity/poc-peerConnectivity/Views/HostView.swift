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

    var body: some View {
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
        }
        .padding(16)
        .onAppear {
            password = generatePassword()
            session.setHostPassword(password)
            session.startAdvertising()
        }
        .onDisappear {
            session.stopAdvertising()
            session.disconnect()
            password = ""
        }
    }
    
    private func generatePassword(length: Int = 6) -> String {
        let charset = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<length).compactMap { _ in charset.randomElement() })
    }
}
