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
            SpriteView(scene: scene, debugOptions: [.showsPhysics, .showsNodeCount])
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                Button("Add ball") {
                    scene.spawnBall()
                }
            }
        }
        .onAppear {
            session.setNotificationHandler(self)
        }
    }
}

extension GameView: MPCNotificationDelegate {
    func notify(_ notification: MPCNotifications) {
        switch notification {
        case .gameMove(let payload):

            let dx = CGFloat(payload.x)
            let sign: CGFloat = dx >= 0 ? 1 : -1

            let newDistance = max(0, abs(dx) - 21)

            let newX = scene.frame.midX + sign * newDistance

            let point = CGPoint(x: newX, y: CGFloat(payload.y))
            print("Parcel entered \(session.myRole)'s view")
            scene.spawnBall(at: point, goingTo: payload.side)

        default:
            break
        }
    }
}

