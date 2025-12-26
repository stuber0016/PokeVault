//
//  InventoryListView.swift
//  PokeVault
//
//  Created by Samuel Luis Štúber on 26.12.2025.
//


import SwiftUI
import SwiftData

struct InventoryListView: View {
    // Fetch data directly from SwiftData
    // @Query(sort: \SavedPokemon.id) private var savedPokemons: [SavedPokemon]
    
    @Query(filter: #Predicate<SavedPokemon> { $0.count > 0 }, sort: \SavedPokemon.id)
    private var savedPokemons: [SavedPokemon]
    
    // Access the P2P Manager
    @EnvironmentObject var p2pManager: P2PManager

    var body: some View {
        List {
            if savedPokemons.isEmpty {
                ContentUnavailableView(
                    "No Pokemon Yet",
                    systemImage: "backpack",
                    description: Text("Go to the Pokedex to add cards, or trade with friends.")
                )
            } else {
                ForEach(savedPokemons) { pokemon in
                    HStack {
                        // Image placeholder until we add caching
                        AsyncImage(url: URL(string: pokemon.spriteURLString)) { image in
                             image.resizable()
                        } placeholder: {
                             Color.gray
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text(pokemon.name.capitalized)
                                .font(.headline)
                            Text("#\(pokemon.id)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("x\(pokemon.count)")
                            .fontWeight(.bold)
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .navigationTitle("My Inventory")
//        .toolbar {
//            ToolbarItem(placement: .topBarTrailing) {
//                // Temporary button to test "Adding" without Coder A
//                Button("Add Test") {
//                    let testMon = Pokemon(saved: SavedPokemon(id: Int.random(in: 1...150), name: "TestMon", spriteURLString: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/1.png"))
//                    StorageManager.shared.addPokemon(testMon)
//                }
//            }
//        }
    }
}
