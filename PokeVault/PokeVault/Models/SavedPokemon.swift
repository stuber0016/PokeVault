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
    
    init(id: Int, name: String, spriteURLString: String, count: Int = 1) {
        self.id = id
        self.name = name
        self.spriteURLString = spriteURLString
        self.count = count
    }
}