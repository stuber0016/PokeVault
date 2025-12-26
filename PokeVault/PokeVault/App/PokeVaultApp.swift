import SwiftUI
import SwiftData

@main
struct PokeVaultApp: App {
    // 1. Initialize the P2P Manager (Shared across the app)
    @StateObject private var p2pManager = P2PManager()
    
    // 2. Initialize the Database Container
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SavedPokemon.self, // We register our Database Model here
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                // Inject the P2P Manager into the environment so any view can find it
                .environmentObject(p2pManager)
        }
        // Inject the Database into the environment
        .modelContainer(sharedModelContainer)
    }
}
