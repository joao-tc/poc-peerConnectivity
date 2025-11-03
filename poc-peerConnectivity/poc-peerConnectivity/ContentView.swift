//
//  ContentView.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 03/11/25.
//

import SwiftUI
import MultipeerConnectivity

struct ContentView: View {
    @StateObject private var peers = PeerService()

    var body: some View {
        VStack(spacing: 16) {
            Text("Multipeer POC")
                .font(.title.bold())

            if peers.connectedPeers.isEmpty {
                Label("Searching & advertising…", systemImage: "wave.3.right")
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Connected peers:")
                        .font(.headline)
                    ForEach(peers.connectedPeers, id: \.self) { peer in
                        Label(peer.displayName, systemImage: "person.2.fill")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Spacer()

            Button("Disconnect / Reset") {
                peers.stop()
                peers.start()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .onAppear { peers.start() }
        .onDisappear { peers.stop() }
    }
}
