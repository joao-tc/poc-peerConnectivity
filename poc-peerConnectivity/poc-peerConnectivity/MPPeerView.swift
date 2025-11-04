//
//  MPPeerView.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 04/11/25.
//

import SwiftUI
import MultipeerConnectivity

struct MPPeerView: View {
    @EnvironmentObject var connectionManager: MPConnectionManager
    
    @State var player1: String = ""
    @State var player2: String = ""
    
    var body: some View {
        VStack {

            HStack {
                Text("Player 1: \(player1)")
                Spacer()
                Text("Player 2: \(player2)")
            }
            .padding(16)

            Text("Available Players")
            
            List(connectionManager.availablePeers, id: \.self) { peer in
                HStack {
                    Text(peer.displayName)
                    Spacer()
                    Button("Select") {
                        connectionManager.nearbyServiceBrowser.invitePeer(peer, to: connectionManager.session, withContext: nil, timeout: 30)
                        
                        player1 = connectionManager.myPeerID.displayName
                        player2 = peer.displayName
                    }
                    .buttonStyle(.borderedProminent)
                }
                .alert("Received Invitation from \(connectionManager.receivedInviteFrom?.displayName ?? "Unknown")", isPresented: $connectionManager.receivedInvite) {
                    Button("Accept") {
                        if let invitationHandler = connectionManager.invitationHandler {
                            invitationHandler(true, connectionManager.session)
                        }
                    }
                    
                    Button("Reject") {
                        if let invitationHandler = connectionManager.invitationHandler {
                            invitationHandler(false, nil)
                        }
                    }
                }
            }
        }
        .onAppear {
            connectionManager.isAvailableToPlay = true
            connectionManager.startBrowsing()
        }
        .onDisappear {
            connectionManager.stopBrowsing()
            connectionManager.stopAdvertising()
            connectionManager.isAvailableToPlay = false
        }
    }
}

#Preview {
    MPPeerView()
        .environmentObject(MPConnectionManager(yourName: "Sample"))
}
