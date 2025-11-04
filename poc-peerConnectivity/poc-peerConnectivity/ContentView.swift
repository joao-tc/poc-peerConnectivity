//
//  ContentView.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 03/11/25.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject var connectionManager: MPConnectionManager
    @AppStorage("yourName") var yourName = ""
    
    init(yourName: String) {
        self.yourName = yourName
        _connectionManager = StateObject(wrappedValue: MPConnectionManager(yourName: yourName))
    }
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}
