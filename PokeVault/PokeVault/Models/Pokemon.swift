//
//  Pokemon.swift
//  PokeVault
//
//  Created by Samuel Luis Štúber on 26.12.2025.
//


import Foundation

// Used for API responses and passing data around
struct Pokemon: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let spriteURL: URL?
    
    // Helper to initialize from your database object later
    init(saved: SavedPokemon) {
        self.id = saved.id
        self.name = saved.name
        self.spriteURL = URL(string: saved.spriteURLString)
    }
}