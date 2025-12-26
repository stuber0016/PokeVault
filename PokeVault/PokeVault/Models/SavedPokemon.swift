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
    // Unique ID ensures we never save "Bulbasaur" twice
    @Attribute(.unique) var id: Int
    var name: String
    var spriteURLString: String
    
    // THE COUNTER:
    // 0 = You see it in Pokedex (gray), but don't own it.
    // 1+ = You own it (Inventory).
    var count: Int
    
    // THE ENDPOINT (Computed Property):
    // We don't save this to the database, we just generate it when we need it.
    // Use this to fetch details: APIService.shared.fetchDetail(url: pokemon.detailURL)
    var detailURL: URL {
        return URL(string: "https://pokeapi.co/api/v2/pokemon/\(id)/")!
    }
    
    // Helper for the Image (so you don't have to convert string manually in Views)
    var imageURL: URL? {
        return URL(string: spriteURLString)
    }
    
    // Init: Default count to 0 because when we seed the DB, we don't own them yet.
    init(id: Int, name: String, spriteURLString: String, count: Int = 0) {
        self.id = id
        self.name = name
        self.spriteURLString = spriteURLString
        self.count = count
    }
}
