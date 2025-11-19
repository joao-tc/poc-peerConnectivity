//
//  Ingredient.swift
//  poc-peerConnectivity
//
//  Created by João Pedro Teixeira de Carvalho on 14/11/25.
//

import Foundation

public struct Ingredient: Codable, Identifiable {
    public var id: UUID
    public let type: IngredientType
    public var state: IngredientState
}

public enum IngredientType: String, Codable {
    case lettuce
    case tomato
    case bread
    case patty
    case potato
    
    case genericParcel
}

public enum IngredientState: String, Codable {
    case base
    case chopped
    case cooked
    case burnt
}
