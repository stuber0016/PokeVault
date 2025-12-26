import SwiftUI
import SwiftData

struct PokedexListView: View {
    // 1. QUERY: Automatically fetches data from the database
    // The view updates instantly when DataSeeder adds items
    @Query(sort: \SavedPokemon.id) var pokemons: [SavedPokemon]
    
    // Grid Layout (2 columns)
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            Group {
                if pokemons.isEmpty {
                    // Show this while downloading the first batch
                    VStack {
                        ProgressView()
                        Text("Downloading Pokedex...")
                            .padding(.top)
                    }
                } else {
                    // The Main List
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(pokemons) { pokemon in
                                PokemonCell(pokemon: pokemon)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Pokedex")
        }
        // 2. THE TRIGGER: This runs the seeder when the view loads
        .task {
            await DataSeeder.shared.seedDatabase()
        }
    }
}

// Helper View for the individual card
struct PokemonCell: View {
    let pokemon: SavedPokemon
    
    var body: some View {
        VStack {
            // Image
            AsyncImage(url: pokemon.imageURL) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFit()
                } else {
                    Color.clear.frame(height: 80) // Placeholder
                }
            }
            .frame(height: 100)
            // Grayscale Logic: Black & White if count is 0
            .saturation(pokemon.count > 0 ? 1.0 : 0.0)
            .opacity(pokemon.count > 0 ? 1.0 : 0.6)
            
            // Name
            Text(pokemon.name.capitalized)
                .font(.headline)
                .foregroundColor(.primary)
            
            // Count Badge
            if pokemon.count > 0 {
                Text("x\(pokemon.count)")
                    .font(.caption)
                    .padding(4)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .overlay(
            // Green border if owned
            RoundedRectangle(cornerRadius: 12)
                .stroke(pokemon.count > 0 ? Color.green : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    // We need to inject a temporary container for the preview to work
    PokedexListView()
        .modelContainer(for: SavedPokemon.self, inMemory: true)
}
