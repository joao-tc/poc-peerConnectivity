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
    
    public init(session: GameSession) {
        self.session = session
    }
    
    var scene: SKScene {
        let scene = PhysicsScene()
        scene.size = UIScreen.main.bounds.size
//        scene.size = UIScreen.scale
        scene.scaleMode = .resizeFill
        return scene
    }
    
    var body: some View {
        SpriteView(scene: scene, debugOptions: [.showsPhysics])
            .ignoresSafeArea()
    }
}

extension GameView: MPCNotificationDelegate {
    func notify(_ notification: MPCNotifications) {
        switch(notification) {
        default:
            break
        }
    }
}

