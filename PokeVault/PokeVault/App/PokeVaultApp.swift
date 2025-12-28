import SwiftUI
import SwiftData

@main
struct PokeVaultApp: App {
    @StateObject private var p2pManager = P2PManager()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(p2pManager)
        }
        // This connects the Database file
        .modelContainer(StorageManager.shared.modelContainer)
    }
}
