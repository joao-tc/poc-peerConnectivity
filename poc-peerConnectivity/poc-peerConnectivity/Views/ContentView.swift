//
//  ContentView.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 03/11/25.
//

import SwiftUI

struct ContentView: View {
    
    @State private var gotoHost: Bool = false
    @State private var gotoJoin: Bool = false

    var body: some View {
        NavigationStack {
            VStack {
                
                Text("POC - Multipeer Connectivity")
                    .font(.title2)
                
                Spacer()
                
                Text("Host or join a game")
                
                HStack {
                    Button("Host") {
                        gotoHost = true
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Spacer()
                    
                    Button("Join") {
                        gotoJoin = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(32)
                
                Spacer()
                
                Text("You must be connected to the same wifi network")
            }
            .padding()
            .navigationDestination(isPresented: $gotoHost) {
                HostView()
            }
            .navigationDestination(isPresented: $gotoJoin) {
                JoinView()
            }
        }
    }
}
