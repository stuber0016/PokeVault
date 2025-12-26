import SwiftData
import SwiftUI

@MainActor
class StorageManager {
    static let shared = StorageManager()

    // 1. Define the Container here (Single Source of Truth)
    let modelContainer: ModelContainer
    let context: ModelContext

    init() {
        do {
            // We define the schema (Your data models)
            let schema = Schema([
                SavedPokemon.self,
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

            // Create the container once
            self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            self.context = modelContainer.mainContext
            print("📂 Database Path: ", URL.applicationSupportDirectory.path(percentEncoded: false))
        } catch {
            fatalError("Could not initialize SwiftData: \(error)")
        }
    }

    // 2. The Logic to Add or Increment
    // Note: We use 'PokemonListEntry' (from your API Models) to pass data in
    func addPokemon(id: Int, name: String, imageURL: String) {
        let descriptor = FetchDescriptor<SavedPokemon>(predicate: #Predicate { $0.id == id })
        
        do {
            // Try to find it in the DB
            if let existing = try context.fetch(descriptor).first {
                existing.count += 1
                print("Incremented \(name) to \(existing.count)")
            } else {
                // If it doesn't exist (unlikely if seeded, but good safety), create it
                let newEntry = SavedPokemon(
                    id: id,
                    name: name,
                    spriteURLString: imageURL,
                    count: 1 // Starts at 1 since we just added it
                )
                context.insert(newEntry)
                print("Created new entry for \(name)")
            }
            try context.save()
        } catch {
            print("Failed to save pokemon: \(error)")
        }
    }
    
    // Decrease count (useful for Trading - sending away a card)
    func removePokemon(id: Int) {
        let descriptor = FetchDescriptor<SavedPokemon>(predicate: #Predicate { $0.id == id })
        do {
            if let existing = try context.fetch(descriptor).first {
                if existing.count > 0 {
                    existing.count -= 1
                    print("Decremented count for ID: \(id)")
                    try context.save()
                }
            }
        } catch {
            print("Error removing pokemon: \(error)")
        }
    }
}
