import SwiftUI
import SwiftData

struct PokedexListView: View {
    // 1. State for the Search Bar
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            PokemonGrid(searchText: searchText)
                .navigationTitle("Pokedex")
                .searchable(
                    text: $searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Search Pokemon"
                )
        }
        .task {
            await DataSeeder.shared.seedDatabase()
        }
    }
}

struct PokemonGrid: View {
    @Query var pokemons: [SavedPokemon]
    
    let searchText: String
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    init(searchText: String) {
        self.searchText = searchText
        
        if searchText.isEmpty {
            _pokemons = Query(sort: \SavedPokemon.id)
        } else {
            _pokemons = Query(
                filter: #Predicate { $0.name.localizedStandardContains(searchText) },
                sort: \SavedPokemon.id
            )
        }
    }
    
    var body: some View {
        Group {
            if pokemons.isEmpty {
                if searchText.isEmpty {
                    VStack {
                        ProgressView()
                        Text("Downloading Pokedex...")
                            .padding(.top)
                    }
                } else {
                    ContentUnavailableView.search(text: searchText)
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(pokemons) { pokemon in
                            NavigationLink(destination: PokemonDetailView(pokemon: pokemon)) {
                                PokemonCell(pokemon: pokemon)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct PokemonCell: View {
    let pokemon: SavedPokemon
    
    var body: some View {
        VStack {
            AsyncImage(url: pokemon.imageURL) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFit()
                } else {
                    Color.clear.frame(height: 80)
                }
            }
            .frame(height: 100)
            .saturation(pokemon.count > 0 ? 1.0 : 0.0)
            .opacity(pokemon.count > 0 ? 1.0 : 0.6)
            
            Text(pokemon.name.capitalized)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)
            
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
            RoundedRectangle(cornerRadius: 12)
                .stroke(pokemon.count > 0 ? Color.green : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    PokedexListView()
        .modelContainer(for: SavedPokemon.self, inMemory: true)
}
