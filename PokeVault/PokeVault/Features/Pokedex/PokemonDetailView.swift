import SwiftUI
import SwiftData

struct PokemonDetailView: View {
    let pokemon: SavedPokemon
    
    // We store the fetched details here (HP, Attack, etc.)
    @State private var details: PokemonDetail?
    @State private var isLoading = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.secondarySystemBackground))
                        .frame(height: 300)
                        .shadow(radius: 5)
                    
                    // The Pokemon Image
                    AsyncImage(url: pokemon.imageURL) { phase in
                        if let image = phase.image {
                            image.resizable()
                                .scaledToFit()
                                .padding()
                        } else {
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    
                    // HP BADGE (Top Left of the Pokemon)
                    if let hp = details?.stats.first(where: { $0.stat.name == "hp" })?.base_stat {
                        VStack {
                            Text("HP")
                                .font(.caption)
                                .bold()
                            Text("\(hp)")
                                .font(.title)
                                .bold()
                                .foregroundColor(.green)
                        }
                        .padding(12)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                        .padding(16)
                    }
                }
                .padding()
                
                // 2. NAME
                Text(pokemon.name.capitalized)
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundColor(.primary)
                
                // 3. STATS LIST
                if isLoading {
                    ProgressView("Loading Stats...")
                } else if let details = details {
                    VStack(spacing: 15) {
                        ForEach(details.stats) { stat in
                            // Skip HP because we showed it at the top
                            if stat.stat.name != "hp" {
                                StatRow(name: stat.stat.name, value: stat.base_stat)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .task {
            await fetchDetails()
        }
    }
    
    // Logic to fetch the extra data live
    func fetchDetails() async {
        do {
            let (data, _) = try await URLSession.shared.data(from: pokemon.detailURL)
            details = try JSONDecoder().decode(PokemonDetail.self, from: data)
            isLoading = false
        } catch {
            print("Failed to fetch details: \(error)")
        }
    }
}

struct StatRow: View {
    let name: String
    let value: Int
    
    var body: some View {
        HStack {
            Text(name.replacingOccurrences(of: "-", with: " ").capitalized)
                .font(.headline)
                .foregroundColor(.gray)
                .frame(width: 120, alignment: .leading)
            
            // Progress Bar Style
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                    
                    Capsule()
                        .fill(statColor)
                        // Max stat is usually around 255, so we calculate width
                        .frame(width: CGFloat(value) / 255.0 * geometry.size.width, height: 12)
                }
            }
            .frame(height: 12)
            
            Text("\(value)")
                .bold()
                .frame(width: 40, alignment: .trailing)
        }
    }
    
    var statColor: Color {
        if value > 100 { return .purple }
        if value > 70 { return .green }
        if value > 40 { return .orange }
        return .red
    }
}

struct PokemonDetail: Codable {
    let stats: [StatEntry]
}

struct StatEntry: Codable, Identifiable {
    let base_stat: Int
    let stat: StatName
    
    var id: String { stat.name }
}

struct StatName: Codable {
    let name: String
}
