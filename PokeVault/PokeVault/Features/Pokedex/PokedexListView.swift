import SwiftUI
import SwiftData

struct PokedexListView: View {
    // 1. State for the Search Bar
    @State private var searchText = ""
    
    @Query(sort: \SavedPokemon.id) var allPokemons: [SavedPokemon]
    @Query(filter: #Predicate<SavedPokemon> { $0.discovered == true })
    
    var discoveredPokemons: [SavedPokemon]
    
    var body: some View {
        NavigationView {
            VStack (spacing: 15) {
                if #available(iOS 26.0, *) {
                    PokemonGrid(searchText: searchText)
                        .navigationTitle("Pokedex")
                        .navigationSubtitle("Found: \(discoveredPokemons.count) / \(allPokemons.count)")
                        .searchable(
                            text: $searchText,
                            placement: .navigationBarDrawer(displayMode: .always),
                            prompt: "Search Pokemon"
                        )
                } else {
                    VStack(spacing: 4) {
                        PokemonGrid(searchText: searchText)
                        Text("Found: \(discoveredPokemons.count) / \(allPokemons.count)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .navigationTitle("Pokedex")
                    .searchable(
                        text: $searchText,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Search Pokemon"
                    )
                }
                
            }
            
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
            .saturation(pokemon.discovered ? 1.0 : 0.0)
            .opacity(pokemon.discovered ? 1.0 : 0.6)
            
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
                .stroke(pokemon.discovered ? Color.green : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    PokedexListView()
        .modelContainer(for: SavedPokemon.self, inMemory: true)
}
