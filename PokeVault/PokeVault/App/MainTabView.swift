//
//  MainTabView.swift
//  PokeVault
//
//  Created by Samuel Luis Štúber on 26.12.2025.
//


import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            // Tab 1: Pokedex (Coder A's work)
            NavigationStack {
                StoreView()
            }
            .tabItem {
                Label("Store ", systemImage: "storefront")
            }
            
            // Tab 2: Pokedex (Coder A's work)
            NavigationStack {
                PokedexListView()
            }
            .tabItem {
                Label("Pokedex", systemImage: "list.bullet")
            }
            
            // Tab 3: Inventory (Your work)
            NavigationStack {
                InventoryListView()
            }
            .tabItem {
                Label("My Cards", systemImage: "backpack")
            }
        }
    }
}

#Preview {
    MainTabView()
}
