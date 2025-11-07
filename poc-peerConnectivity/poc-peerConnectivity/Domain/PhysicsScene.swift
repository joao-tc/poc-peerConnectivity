//
//  PhysicsScene.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 07/11/25.
//

import SpriteKit

public final class PhysicsScene: SKScene {
    
    private var ball: SKShapeNode!
    private let ballSize: CGFloat = 40
    
    private var dragJoint: SKPhysicsJointSpring?
    private var dragHandle: SKNode?
    
    override public func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
        physicsWorld.gravity = .zero
        
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        
        ball = SKShapeNode(circleOfRadius: ballSize)
        ball.fillColor = .systemBlue
        ball.strokeColor = .white
        ball.position = .init(x: 0, y: 0)
        ball.name = "draggable"
        
        ball.physicsBody = SKPhysicsBody(circleOfRadius: ballSize)
        ball.physicsBody?.affectedByGravity = false
        ball.physicsBody?.linearDamping = 1.2
        ball.physicsBody?.angularDamping = 1.2
        
        addChild(ball)
    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        if ball.contains(location) {
            let handle = SKNode()
            handle.position = location
            handle.physicsBody = SKPhysicsBody(circleOfRadius: 1)
            handle.physicsBody?.isDynamic = false
            addChild(handle)
            dragHandle = handle
            
            let joint = SKPhysicsJointSpring.joint(withBodyA: ball.physicsBody!, bodyB: handle.physicsBody!, anchorA: ball.position, anchorB: location)
            joint.frequency = 3
            joint.damping = 2
            
            physicsWorld.add(joint)
            dragJoint = joint
        }
    }
    
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let handle = dragHandle else { return }
        handle.position = touch.location(in: self)
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        endDrag()
    }
    
    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        endDrag()
    }
    
    private func endDrag() {
        if let joint = dragJoint { physicsWorld.remove(joint) }
        dragJoint = nil
        dragHandle?.removeFromParent()
        dragHandle = nil
    }
}
