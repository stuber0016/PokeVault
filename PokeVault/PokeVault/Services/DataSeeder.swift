import Foundation
import SwiftData

class DataSeeder {
    static let shared = DataSeeder()
    
    @MainActor
    func seedDatabase() async {
        let context = StorageManager.shared.context
        
        // 1. Check if we already have Pokemon
        // We use a simple fetch to see if the DB is empty or full
        let descriptor = FetchDescriptor<SavedPokemon>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        
        if count >= 500 {
            print("Database already has \(count) pokemon. Skipping seed.")
            return
        }
        
        print("Starting Seed: Fetching 500 Pokemon...")
        
        // 2. Fetch from API (One big batch is faster than looping pages)
        let urlString = "https://pokeapi.co/api/v2/pokemon?limit=500"
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            // Decode using the API Models we made earlier
            let response = try JSONDecoder().decode(PokemonListResponse.self, from: data)
            
            // 3. Loop and Save
            for entry in response.results {
                // Check if this specific ID exists (to avoid duplicates if seed crashed halfway)
                let id = entry.id
                let exists = try? context.fetchCount(FetchDescriptor<SavedPokemon>(predicate: #Predicate { $0.id == id }))
                
                if exists == 0 {
                    let newPokemon = SavedPokemon(
                        id: entry.id,
                        name: entry.name,
                        spriteURLString: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/\(entry.id).png",
                        count: 0 // Default to 0 (Not Owned)
                    )
                    context.insert(newPokemon)
                }
            }
            
            // 4. Save to Disk
            try context.save()
            print("Seeding Complete! Saved \(response.results.count) pokemon.")
            
        } catch {
            print("Seeding Failed: \(error)")
        }
    }
}