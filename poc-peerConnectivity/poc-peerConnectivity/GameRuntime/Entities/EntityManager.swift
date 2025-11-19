//
//  EntityManager.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 10/11/25.
//

import Foundation
import GameplayKit
import SpriteKit

public final class EntityManager {

    // Set with all entities on the scene
    private var entities = Set<GKEntity>()
    
    // Access to the scene
    private var scene: SKScene

    // Initializer
    public init(scene: SKScene) {
        self.scene = scene
    }

    // Add a new entity to the scene
    public func add(entity: GKEntity) {
        entities.insert(entity)

        if let node = entity.component(ofType: GKSKNodeComponent.self)?.node {
            scene.addChild(node)
        }
    }
    
    // Removes an enitity from the scene
    public func remove(entity: GKEntity) {
        entities.remove(entity)
        
        if let node = entity.component(ofType: GKSKNodeComponent.self)?.node {
            node.removeFromParent()
        }
    }
    
    // Returns the set with all entities
    public func getEntities() -> Set<GKEntity> {
        entities
    }
}

// Hit-test helpers
extension EntityManager {
    
    // Returns the top-most entity on a given position
    public func entity(at point: CGPoint) -> GKEntity? {
        
        let candidates: [(GKEntity, SKNode)] = entities.compactMap { entity in
            guard
                entity.component(ofType: DraggableComponent.self) != nil,
                let node = entity.component(ofType: GKSKNodeComponent.self)?.node,
                node.contains(point),
                node.physicsBody != nil
            else { return nil }
            return (entity, node)
        }
        
        return candidates.max(by: { $0.1.zPosition < $1.1.zPosition })?.0
    }
    
    // Exposes access to an entity's node
    public func node(for entity: GKEntity) -> SKNode? {
        entity.component(ofType: GKSKNodeComponent.self)?.node
    }
}
