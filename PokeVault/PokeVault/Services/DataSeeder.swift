//
//  DataSeeder.swift
//  PokeVault
//
//  Created by Petr Herčko on 26.12.2025.
//


import Foundation
import SwiftData

class DataSeeder {
    static let shared = DataSeeder()
    
    @MainActor
    func seedDatabase() async {
        let context = StorageManager.shared.context
        
        let descriptor = FetchDescriptor<SavedPokemon>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        
        if count > 0 {
            print("Database already has \(count) pokemon. Skipping seed.")
            return
        }
        
        print("Starting Seed: Fetching 500 Pokemon...")
        
        let urlString = "https://pokeapi.co/api/v2/pokemon/?limit=500&offset=0"
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(PokemonListResponse.self, from: data)
            for entry in response.results {
                print(entry)
                let id = entry.id
                let exists = try? context.fetchCount(FetchDescriptor<SavedPokemon>(predicate: #Predicate { $0.id == id }))
                
                if exists == 0 {
                    let newPokemon = SavedPokemon(
                        id: entry.id,
                        name: entry.name,
                        spriteURLString: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/\(entry.id).png",
                        count: 0,
                        discovered: false
                    )
                    context.insert(newPokemon)
                }
            }
            try context.save()
            print("Seeding Complete! Saved \(response.results.count) pokemon.")
            
        } catch {
            print("Seeding Failed: \(error)")
        }
    }
}
