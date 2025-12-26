//
//  StorageManager.swift
//  PokeVault
//
//  Created by Samuel Luis Štúber on 26.12.2025.
//


import SwiftData
import SwiftUI

@MainActor
class StorageManager {
    private let modelContainer: ModelContainer
    private let context: ModelContext

    static let shared = StorageManager() // Singleton for simplicity in 2-day project

    init() {
        // Initialize SwiftData
        do {
            modelContainer = try ModelContainer(for: SavedPokemon.self)
            context = modelContainer.mainContext
        } catch {
            fatalError("Could not initialize SwiftData: \(error)")
        }
    }

    func addPokemon(_ pokemon: Pokemon) {
        // Check if we already have it
        let id = pokemon.id
        let descriptor = FetchDescriptor<SavedPokemon>(predicate: #Predicate { $0.id == id })
        
        do {
            if let existing = try context.fetch(descriptor).first {
                existing.count += 1
                print("Incremented count for \(pokemon.name)")
            } else {
                let newEntry = SavedPokemon(
                    id: pokemon.id, 
                    name: pokemon.name, 
                    spriteURLString: pokemon.spriteURL?.absoluteString ?? ""
                )
                context.insert(newEntry)
                print("Created new entry for \(pokemon.name)")
            }
            try context.save() // Persist changes
        } catch {
            print("Failed to save pokemon: \(error)")
        }
    }
    
    func getAll() -> [SavedPokemon] {
        let descriptor = FetchDescriptor<SavedPokemon>(sortBy: [SortDescriptor(\.id)])
        return (try? context.fetch(descriptor)) ?? []
    }
}