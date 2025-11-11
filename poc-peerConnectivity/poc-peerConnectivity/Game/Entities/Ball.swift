//
//  Ball.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 10/11/25.
//

import Foundation
import SpriteKit
import GameplayKit

public class Ball: GKEntity {
    
    private var ballSize: CGFloat = 40
    
    public var node: SKNode? {
        component(ofType: GKSKNodeComponent.self)?.node
    }
    
    public var body: SKPhysicsBody? {
        node?.physicsBody
    }
    
    override public init() {
        super.init()

        let node = SKShapeNode(circleOfRadius: ballSize)
        
        node.name = "ball"
        node.fillColor = .systemBlue
        node.strokeColor = .white

        node.physicsBody = SKPhysicsBody(circleOfRadius: ballSize)
        node.physicsBody?.affectedByGravity = false
        node.physicsBody?.categoryBitMask = PhysicsCategory.parcel
        node.physicsBody?.collisionBitMask = PhysicsCategory.edge
        node.physicsBody?.contactTestBitMask =
            PhysicsCategory.sensorLeft | PhysicsCategory.sensorRight
        node.physicsBody?.linearDamping = 10
        node.physicsBody?.angularDamping = 10
        
        addComponent(GKSKNodeComponent(node: node))
        
        let draggableComponent = DraggableComponent()
        addComponent(draggableComponent)
    }
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setPosition(to point: CGPoint) {
        component(ofType: GKSKNodeComponent.self)?.node.position = point
    }
}
