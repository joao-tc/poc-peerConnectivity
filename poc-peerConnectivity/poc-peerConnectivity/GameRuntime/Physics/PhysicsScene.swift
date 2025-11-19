//
//  PhysicsScene.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 07/11/25.
//

import SpriteKit
import GameplayKit

public final class PhysicsScene: SKScene {

    // Game session - transport layer + game handling features
    private var session: GameSession
    
    // Entity manager - used to manage entities 😃
    private var entityManager: EntityManager?

    // Initializers
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
    /***/

    // Dragging-related variables
    private var isDragging = false
    private var currentDrag: GKEntity?
    private var targetPoint: CGPoint?

    // Scene 'initializer'- triggered when the SKView is rendered
    override public func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
        physicsWorld.gravity = .init(dx: 0, dy: 9.6)

        self.entityManager = EntityManager(scene: self)
        
        spawnBall()
    }

    // MARK: - Touch funcs
    
    // Touches began - triggered when a touch is initialized
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
    
    // Touches moved - triggered when the user drags the finger on the screen
    override public func touchesMoved(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        guard let touch = touches.first else { return }
        targetPoint = touch.location(in: self)
    }

    // Touches ended/cancelled - triggered when the user stops touching the screen
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
    /***/

    // End drag - used to reset all dragging-related variables
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

    // Update - acts as the 'tick' function, being called right before each rendering iteration
    override public func update(_ currentTime: TimeInterval) {
        handleMovementUpdate()
        
        guard let entities = entityManager?.getEntities() else { return }
        
        for entity in entities {
            if let node = entity.component(ofType: GKSKNodeComponent.self)?.node {
                if let side = exitSide(for: node) {
                    print("Ball from \(session.myID.rawValue) exited to the \(side)")
                    sendParcelHorizontally(side: side, node: node, entity: entity)
                }
            }
        }
    }

    // Did change size - triggered whenever the app view changes its size (ex.: rotate the phone)
    public override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody?.categoryBitMask = PhysicsCategory.edge
        // Rebuild sensors to match new size (or update their frames)
        children.filter { $0.name?.hasPrefix("sensor.") == true }.forEach {
            $0.removeFromParent()
        }
    }
}

// MARK: - Send and Spawn functions
extension PhysicsScene {
    
    // Send parecl horizontally - Sends a parcel horizontally
    private func sendParcelHorizontally(
        side: EdgeSide,
        node: SKNode,
        entity: GKEntity
    ) {
        entityManager?.remove(entity: entity)
        let dxFromCenter = node.position.x - frame.midX
        let mirroredDx = -dxFromCenter

        let payload = GamePayload(
            x: mirroredDx,
            y: node.position.y,
            side: side
        )
        
        session.sendParcelHorizontally(payload)
    }

    // Spawn ball - used as a debug/development function, spawns a ball
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
    
    public func spawnBall(at point: CGPoint, goingTo side: EdgeSide) {
        let ball = Ball()
        ball.setPosition(to: point)
        entityManager?.add(entity: ball)
        let direction: CGFloat = side == .right ? 1 : -1
        ball.body?.applyForce(.init(dx: 7500 * direction, dy: 0))
    }
    /***/
}

// MARK: - Parcel movement
extension PhysicsScene {
    
    // Handle movement update - used to manage the dragging mechanic, adds a force to the dragged object in the direction of the touch position
    private func handleMovementUpdate() {
        guard
            let manager = entityManager,
            let entity = currentDrag,
            let node = manager.node(for: entity),
            let body = node.physicsBody,
            let target = targetPoint
        else { return }
        
        node.zRotation = .zero

        let pos = node.position
        let dx = target.x - pos.x
        let dy = target.y - pos.y
        let dist = sqrt(dx * dx + dy * dy)
        if dist < 0.5 {
            body.velocity = .zero
            return
        }

        let stiffness: CGFloat = 20
        let damping: CGFloat = 10

        let desiredVx = dx * stiffness
        let desiredVy = dy * stiffness

        let steerX = desiredVx - body.velocity.dx
        let steerY = desiredVy - body.velocity.dy

        let force = CGVector(dx: steerX * damping, dy: steerY * damping)
        body.applyForce(force)

        let maxSpeed: CGFloat = 1000
        var velocity = body.velocity
        let speed = hypot(velocity.dx, velocity.dy)
        if speed > maxSpeed {
            velocity.dx = velocity.dx / speed * maxSpeed
            velocity.dy = velocity.dy / speed * maxSpeed
            body.velocity = velocity
        }
    }
    
    // Exit side - triggered whenever a parcel exits the sides (horizontally) triggering notification/sending functions
    private func exitSide(for node: SKNode, minExitVelocity velocity: CGFloat = 1) -> EdgeSide? {
        guard let body = node.physicsBody else { return nil }
        
        let accFrame = node.calculateAccumulatedFrame()
        
        if accFrame.maxX < frame.minX + 20, body.velocity.dx < -velocity {
            return .left
        }
        
        if accFrame.minX > frame.maxX - 20, body.velocity.dx > velocity {
            return .right
        }
        
        return nil
    }
}
