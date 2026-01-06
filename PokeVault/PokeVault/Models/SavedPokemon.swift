//
//  SavedPokemon.swift
//  PokeVault
//
//  Created by Samuel Luis Štúber on 26.12.2025.
//


import Foundation
import SwiftData

@Model
final class SavedPokemon {
    @Attribute(.unique) var id: Int
    var name: String
    var spriteURLString: String
    var count: Int
    var discovered: Bool
    var detailURL: URL {
        return URL(string: "https://pokeapi.co/api/v2/pokemon/\(id)/")!
    }
    
    var imageURL: URL? {
        return URL(string: spriteURLString)
    }
    
    init(id: Int, name: String, spriteURLString: String, count: Int = 0, discovered: Bool = false) {
        self.id = id
        self.name = name
        self.spriteURLString = spriteURLString
        self.count = count
        self.discovered = count > 0 ? true : discovered
    }
}
