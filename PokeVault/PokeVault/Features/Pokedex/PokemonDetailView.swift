import SwiftUI
import SwiftData

struct PokemonDetailView: View {
    let pokemon: SavedPokemon
    @State private var details: PokemonDetail?

    @State private var species: PokemonSpecies?
    
    @State private var isLoading = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // MAIN CARD
                ZStack(alignment: .top) {
                    
                    RoundedRectangle(cornerRadius: 30)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    rarityInfo.color.opacity(0.6),
                                    Color(.secondarySystemBackground)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 350)
                        .shadow(color: rarityInfo.color.opacity(0.4), radius: 10, x: 0, y: 5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(rarityInfo.color, lineWidth: (species?.is_legendary == true || species?.is_mythical == true) ? 2 : 0)
                        )
                   
                    AsyncImage(url: pokemon.imageURL) { phase in
                        if let image = phase.image {
                            image.resizable()
                                .scaledToFit()
                                .padding(.top, 50)
                                .padding(.bottom, 20)
                                .padding(.horizontal)
                        } else {
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: 350)
                        }
                    }
                    .saturation(pokemon.count > 0 ? 1.0 : 0.0)
                    .opacity(pokemon.count > 0 ? 1.0 : 0.6)

                    HStack(alignment: .top) {
                        
                        if let hp = details?.stats.first(where: { $0.stat.name == "hp" })?.base_stat {
                            VStack {
                                Text("HP")
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(.secondary)
                                Text("\(hp)")
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(.green)
                            }
                            .frame(width: 60, height: 60)
                            .background(Color(.systemBackground).opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(radius: 4)
                        }
                        
                        Spacer()
                        
                        if let _ = species {
                            VStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(rarityInfo.color)
                                    .font(.caption)
                                
                                Text(rarityInfo.title)
                                    .font(.caption)
                                    .fontWeight(.heavy)
                                    .foregroundColor(rarityInfo.color)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(10)
                            .frame(minWidth: 60, minHeight: 60)
                            .background(Color(.systemBackground).opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(radius: 4)
                        }
                    }
                    .padding(20)
                }
                .padding()

                VStack(spacing: 5) {
                    Text(pokemon.name.capitalized)
                        .font(.system(size: 40, weight: .heavy))
                        .foregroundColor(.primary)
                    
                    HStack {
                        Image(systemName: pokemon.count > 0 ? "checkmark.circle.fill" : "lock.fill")
                        Text(pokemon.count > 0 ? "In Collection (x\(pokemon.count))" : "Not Caught Yet")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(pokemon.count > 0 ? .green : .secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        (pokemon.count > 0 ? Color.green : Color.gray).opacity(0.15)
                    )
                    .clipShape(Capsule())
                }
                if isLoading {
                    ProgressView("Loading Data...")
                } else if let details = details {
                    VStack(spacing: 15) {
                        ForEach(details.stats) { stat in
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
    
    var rarityInfo: (title: String, color: Color) {
        guard let s = species else { return ("", .gray) }
        
        if s.is_mythical { return ("MYTHICAL", .pink) }
        if s.is_legendary { return ("LEGENDARY", .yellow) }
        
        if s.capture_rate < 50 { return ("VERY RARE", .purple) }
        if s.capture_rate < 100 { return ("RARE", .blue) }
        if s.capture_rate < 200 { return ("UNCOMMON", .orange) }
        
        return ("COMMON", .green)
    }
    
    func fetchDetails() async {
        do {
            let (data, _) = try await URLSession.shared.data(from: pokemon.detailURL)
            let decodedDetails = try JSONDecoder().decode(PokemonDetail.self, from: data)
            self.details = decodedDetails
            
            if let url = URL(string: decodedDetails.species.url) {
                let (speciesData, _) = try await URLSession.shared.data(from: url)
                self.species = try JSONDecoder().decode(PokemonSpecies.self, from: speciesData)
            }
            
            isLoading = false
        } catch {
            print("Failed to fetch details: \(error)")
            isLoading = false
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
                .foregroundColor(.secondary)
                .frame(width: 110, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                    
                    Capsule()
                        .fill(statColor)
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

// MARK: - Models

struct PokemonDetail: Codable {
    let stats: [StatEntry]
    let species: SpeciesReference
}

struct StatEntry: Codable, Identifiable {
    let base_stat: Int
    let stat: StatName
    
    var id: String { stat.name }
}

struct StatName: Codable {
    let name: String
}

struct SpeciesReference: Codable {
    let url: String
}

struct PokemonSpecies: Codable {
    let is_legendary: Bool
    let is_mythical: Bool
    let capture_rate: Int
}
