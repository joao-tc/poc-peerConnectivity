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
    
    private var isDragging = false
    private var targetPoint: CGPoint?
    
    override public func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
        physicsWorld.gravity = .zero
        
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        
        ball = SKShapeNode(circleOfRadius: ballSize)
        ball.fillColor = .systemBlue
        ball.strokeColor = .white
        ball.position = .init(x: frame.midX, y: frame.midY)
        ball.name = "draggable"
        
        ball.physicsBody = SKPhysicsBody(circleOfRadius: ballSize)
        ball.physicsBody?.affectedByGravity = false
        ball.physicsBody?.linearDamping = 10
        ball.physicsBody?.angularDamping = 10
        
        addChild(ball)
    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        guard ball.contains(position), let body = ball.physicsBody else { return }
        
        isDragging = true
        targetPoint = location
        body.angularVelocity = 0
    }
    
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        targetPoint = touch.location(in: self)
        isDragging = true
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        endDrag()
    }
    
    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        endDrag()
    }
    
    private func endDrag() {
        isDragging = false
        targetPoint = nil
        if let body = ball.physicsBody {
            body.angularVelocity = 0
        }
    }
    
    override public func update(_ currentTime: TimeInterval) {
        guard isDragging,
              let target = targetPoint,
              let body = ball.physicsBody
        else { return }
        
        
        let pos = ball.position
        let dx = target.x - pos.x
        let dy = target.y - pos.y
        let dist = sqrt(dx*dx + dy*dy)
        if dist < 0.5 { body.velocity = .zero; return }
        
        let stiffness: CGFloat = 60
        let damping: CGFloat = 12
        
        let desiredVx = dx * stiffness
        let desiredVy = dy * stiffness
        
        let steerX = desiredVx - body.velocity.dx
        let steerY = desiredVy - body.velocity.dy
        
        let force = CGVector(dx: steerX * damping, dy: steerY * damping)
        body.applyForce(force)
        
        let maxSpeed: CGFloat = 600
        var velocity = body.velocity
        let speed = hypot(velocity.dx, velocity.dy)
        if speed > maxSpeed {
            velocity.dx = velocity.dx / speed * maxSpeed
            velocity.dy = velocity.dy / speed * maxSpeed
            body.velocity = velocity
        }
    }
}
