import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            // Tab 1: Pokedex (Coder A's work)
            NavigationStack {
                PokedexListView()
            }
            .tabItem {
                Label("Pokedex", systemImage: "list.bullet")
            }
            
            // Tab 2: Inventory (Your work)
            NavigationStack {
                InventoryListView()
            }
            .tabItem {
                Label("My Cards", systemImage: "backpack")
            }
        }
    }
}