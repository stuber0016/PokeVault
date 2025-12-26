import SwiftUI
import SwiftData

@main
struct PokeVaultApp: App {
    @StateObject private var p2pManager = P2PManager()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(p2pManager)
                // Now this works because StorageManager is ObservableObject!
        }
        // This connects the Database file
        .modelContainer(StorageManager.shared.modelContainer)
    }
}
