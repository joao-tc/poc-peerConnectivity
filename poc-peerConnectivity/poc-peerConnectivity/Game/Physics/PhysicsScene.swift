//
//  PhysicsScene.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 07/11/25.
//

import SpriteKit
import GameplayKit

public final class PhysicsScene: SKScene {

    private var session: GameSession
    private var entityManager: EntityManager?

    public init(session: GameSession, size: CGSize) {
        self.session = session
        super.init(size: size)
    }

    public override convenience init(size: CGSize) {
        fatalError("Use PhysicsScene(session:size:) instead")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var isDragging = false
    private var currentDrag: GKEntity?
    private var targetPoint: CGPoint?

    override public func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
        physicsWorld.gravity = .init(dx: 0, dy: 9.6)
        physicsWorld.contactDelegate = self

        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody?.categoryBitMask = PhysicsCategory.edge

        addSideSensors(withThickness: 8)
        
        self.entityManager = EntityManager(scene: self)
        
        spawnBall()
    }

    // MARK: - Touch funcs
    override public func touchesBegan(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        guard
            let touch = touches.first,
            let manager = entityManager
        else { return }
        
        let location = touch.location(in: self)
        
        guard
            let entity = manager.entity(at: location),
            let node = manager.node(for: entity),
            let body = node.physicsBody
        else { return }

        isDragging = true
        currentDrag = entity
        targetPoint = location
        body.angularVelocity = 0
    }

    override public func touchesMoved(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        guard let touch = touches.first else { return }
        targetPoint = touch.location(in: self)
    }

    override public func touchesEnded(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        endDrag()
    }

    override public func touchesCancelled(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        endDrag()
    }

    private func endDrag() {
        isDragging = false
        
        defer {
            currentDrag = nil
            targetPoint = nil
        }
        
        guard
            let manager = entityManager,
            let entity = currentDrag,
            let node = manager.node(for: entity),
            let body = node.physicsBody
        else { return }
        
        body.angularVelocity = 0
    }
    // MARK: -

    override public func update(_ currentTime: TimeInterval) {
        guard
            let manager = entityManager,
            let entity = currentDrag,
            let node = manager.node(for: entity),
            let body = node.physicsBody,
            let target = targetPoint
        else { return }

        let pos = node.position
        let dx = target.x - pos.x
        let dy = target.y - pos.y
        let dist = sqrt(dx * dx + dy * dy)
        if dist < 0.5 {
            body.velocity = .zero
            return
        }

        let stiffness: CGFloat = 20
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

    private func addSideSensors(withThickness thickness: CGFloat) {
        // Left sensor
        let leftRect = CGRect(
            x: frame.minX - thickness,
            y: frame.minY,
            width: thickness,
            height: frame.height
        )
        let leftNode = SKNode()
        leftNode.name = "sensor.left"
        leftNode.physicsBody = SKPhysicsBody(edgeLoopFrom: leftRect)
        leftNode.physicsBody?.isDynamic = false
        leftNode.physicsBody?.categoryBitMask = PhysicsCategory.sensorLeft
        leftNode.physicsBody?.collisionBitMask = 0
        leftNode.physicsBody?.contactTestBitMask = 0
        addChild(leftNode)

        // Right sensor
        let rightRect = CGRect(
            x: frame.maxX,
            y: frame.minY,
            width: thickness,
            height: frame.height
        )
        let rightNode = SKNode()
        rightNode.name = "sensor.right"
        rightNode.physicsBody = SKPhysicsBody(edgeLoopFrom: rightRect)
        rightNode.physicsBody?.isDynamic = false
        rightNode.physicsBody?.categoryBitMask = PhysicsCategory.sensorRight
        rightNode.physicsBody?.collisionBitMask = 0
        rightNode.physicsBody?.contactTestBitMask = 0
        addChild(rightNode)
    }

    public override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody?.categoryBitMask = PhysicsCategory.edge
        // Rebuild sensors to match new size (or update their frames)
        children.filter { $0.name?.hasPrefix("sensor.") == true }.forEach {
            $0.removeFromParent()
        }
        addSideSensors(withThickness: 8)
    }

    private func sendParcel(
        side: EdgeSide,
        node: SKNode
    ) {
        node.removeFromParent()
        let payload = GamePayload(x: node.position.x * -1, y: node.position.y, side: side)
        let message = MPCMessage.game(payload)
        session.send(message: message)
    }

    public func spawnBall() {
        let ball = Ball()
        let point: CGPoint = .init(x: frame.midX, y: frame.midY)
        ball.setPosition(to: point)
        entityManager?.add(entity: ball)
    }
    
    public func spawnBall(at point: CGPoint) {
        let ball = Ball()
        ball.setPosition(to: point)
        entityManager?.add(entity: ball)
    }
    
    public func spawnBall(at point: CGPoint, from side: EdgeSide) {
        let ball = Ball()
        ball.setPosition(to: point)
        entityManager?.add(entity: ball)
        let direction: CGFloat = side == .right ? 1 : -1
        ball.body?.applyForce(.init(dx: 5000 * direction, dy: 0))
    }
}

// MARK: - Collision Delegate
public enum EdgeSide: String, Codable { case left, right }

extension PhysicsScene: SKPhysicsContactDelegate {
    public func didBegin(_ contact: SKPhysicsContact) {
        let bodies = (contact.bodyA, contact.bodyB)
        guard
            let parcelBody = [bodies.0, bodies.1].first(where: {
                $0.categoryBitMask & PhysicsCategory.parcel != 0
            }),
            let sensorBody = [bodies.0, bodies.1].first(where: {
                $0.categoryBitMask
                    & (PhysicsCategory.sensorLeft | PhysicsCategory.sensorRight)
                    != 0
            }),
            let parcelNode = parcelBody.node as? SKShapeNode
        else { return }

        let isLeft =
            sensorBody.categoryBitMask & PhysicsCategory.sensorRight != 0
        let side: EdgeSide = isLeft ? .left : .right
        sendParcel(side: side, node: parcelNode)
    }
}
