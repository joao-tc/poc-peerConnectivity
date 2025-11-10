//
//  GameView.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 07/11/25.
//

import SwiftUI
import SpriteKit

struct GameView: View {
    
    @ObservedObject private var session: GameSession
    @State private var scene: PhysicsScene
    
    public init(session: GameSession) {
        self.session = session
        let initialSize = UIScreen.main.bounds.size
        _scene = State(wrappedValue: PhysicsScene(session: session, size: initialSize))
    }
    
    var body: some View {
        
        ZStack {
            SpriteView(scene: scene, debugOptions: [.showsPhysics])
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                Button("Add ball") {
                    scene.spawnBall()
                }
            }
        }
        .onAppear {
            session.notificationHandler = self
        }
    }
}

extension GameView: MPCNotificationDelegate {
    func notify(_ notification: MPCNotifications) {
        switch(notification) {
        
        case .gameMove(let payload):
            let point: CGPoint = .init(x: payload.x * -1, y: payload.y)
            scene.spawnBall(at: point)
            
        default:
            break
        }
    }
}

