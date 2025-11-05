//
//  HostView.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 04/11/25.
//

import MultipeerConnectivity
import SwiftUI

struct HostView: View {

    @ObservedObject private var session = GameSession()

    @State private var password: String = ""

    var body: some View {
        VStack {
            Text("Hosting Game")

            HStack {
                TextField("password", text: $password)
                    .padding(16)
                
                Button("Apply") {
                    guard !password.isEmpty else { return }
                    session.setHostPassword(password)
                }
                .buttonStyle(.borderedProminent)
            }

            Spacer()

            VStack {
                Text("Connected peers")
                ForEach(session.connectedPeers, id: \.self) { peer in
                    Text(peer.displayName)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .onAppear {
            session.setHostPassword(password)
            session.startAdvertising()
        }
        .onDisappear {
            session.stopAdvertising()
            session.disconnect()
        }
    }
}

#Preview {
    HostView()
}
