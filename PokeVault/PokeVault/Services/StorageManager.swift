import SwiftData
import SwiftUI

@MainActor
class StorageManager {
    static let shared = StorageManager()

    let modelContainer: ModelContainer
    let context: ModelContext

    init() {
        do {
            let schema = Schema([
                SavedPokemon.self,
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

            self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            self.context = modelContainer.mainContext
            print("Database Path: ", URL.applicationSupportDirectory.path(percentEncoded: false))
        } catch {
            fatalError("Could not initialize SwiftData: \(error)")
        }
    }
    
    func getPokedexStats() -> (found: Int, total: Int) {
        
        do {
            let totalDescriptor = FetchDescriptor<SavedPokemon>()
            let totalCount = try context.fetchCount(totalDescriptor)
            let foundDescriptor = FetchDescriptor<SavedPokemon>(
                predicate: #Predicate { $0.discovered == true }
            )
            let foundCount = try context.fetchCount(foundDescriptor)
            
            return (foundCount, totalCount)
            
        } catch {
            return (0, 0)
        }
    }

    func addPokemon(id: Int, name: String, imageURL: String) {
        let descriptor = FetchDescriptor<SavedPokemon>(predicate: #Predicate { $0.id == id })
        
        do {
            if let existing = try context.fetch(descriptor).first {
                existing.count += 1
                existing.discovered = true
                print("Incremented \(name) to \(existing.count)")
            } else {
                let newEntry = SavedPokemon(
                    id: id,
                    name: name,
                    spriteURLString: imageURL,
                    count: 1,
                    discovered: true
                )
                context.insert(newEntry)
                print("Created new entry for \(name)")
            }
            try context.save()
        } catch {
            print("Failed to save pokemon: \(error)")
        }
    }
    

    func incrementPokemon(id: Int) -> Pokemon? {
            let descriptor = FetchDescriptor<SavedPokemon>(predicate: #Predicate { $0.id == id })
            
            do {
                if let existing = try context.fetch(descriptor).first {
                    existing.count += 1
                    existing.discovered = true
                    try context.save()
                    print("Incremented count for \(existing.name)")
                    return Pokemon(saved: existing)
                } else {
                    print("Error: Pokemon ID \(id) not found in DB. Coder A should have seeded this!")
                    return nil
                }
            } catch {
                print("Failed to increment: \(error)")
                return nil
            }
        }
        
    func decrementPokemon(id: Int) {
            let descriptor = FetchDescriptor<SavedPokemon>(predicate: #Predicate { $0.id == id })
            
            do {
                if let existing = try context.fetch(descriptor).first, existing.count > 0 {
                    existing.count -= 1
                    try context.save()
                }
            } catch {
                print("Failed to decrement: \(error)")
            }
        }
    
    func getPokemon(id: Int) -> Pokemon? {
            let descriptor = FetchDescriptor<SavedPokemon>(predicate: #Predicate { $0.id == id })
            return try? context.fetch(descriptor).first.map { Pokemon(saved: $0) }
        }
    
}
