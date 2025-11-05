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
    
    var body: some View {
        
        VStack {
            Text("Join game")
            
            HStack {
                TextField("passowrd", text: $password)
                Spacer()
                Button("Join") {
                    guard !password.isEmpty else { return }
                    tryToJoin(withPassword: password)
                }
                .buttonStyle(.automatic)
            }
            .padding(16)
        }
        .padding(16)
        .onAppear {
            session.startBrowsing()
        }
        .onDisappear {
            session.stopBrowsing()
            session.disconnect()
        }
    }
    
    private func tryToJoin(withPassword password: String) {
        for peer in session.possiblePeers {
            session.sendInvite(to: peer, withPassword: password)
        }
    }
}


