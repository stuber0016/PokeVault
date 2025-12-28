import SwiftUI
import SwiftData

struct PokemonDetailView: View {
    let pokemon: SavedPokemon
    @AppStorage("isDebugMode") private var isDebugMode = false
    
    @State private var details: PokemonDetail?
    @State private var species: PokemonSpecies?
    @State private var nextEvolution: EvolutionTarget?
    @State private var entireEvolutionChain: [EvolutionTarget] = []
    @State private var isLoading = true
    @State private var showEvolutionScreen = false
    
    var evolutionCost: Int {
        guard let s = species else { return 3 }
        if s.is_legendary || s.is_mythical { return 10 }
        if s.capture_rate < 50 { return 5 }
        return 3
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [rarityInfo.color.opacity(0.6), Color(.secondarySystemBackground)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 350)
                        .shadow(color: rarityInfo.color.opacity(0.4), radius: 10, x: 0, y: 5)
                    
                    AsyncImage(url: pokemon.imageURL) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFit()
                                .padding(.top, 50).padding(.bottom, 20).padding(.horizontal)
                        } else {
                            ProgressView().frame(height: 350)
                        }
                    }
                    .saturation(pokemon.discovered ? 1.0 : 0.0)
                    .opacity(pokemon.discovered ? 1.0 : 0.6)
                    
                    HStack(alignment: .top) {
                        if let hp = details?.stats.first(where: { $0.stat.name == "hp" })?.base_stat {
                            VStack {
                                Text("HP").font(.caption).bold().foregroundColor(.secondary)
                                Text("\(hp)").font(.title2).bold().foregroundColor(.green)
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
                                    .foregroundColor(rarityInfo.color).font(.caption)
                                Text(rarityInfo.title)
                                    .font(.caption).fontWeight(.heavy)
                                    .foregroundColor(rarityInfo.color)
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
                
                VStack(spacing: 15) {
                    Text(pokemon.name.capitalized)
                        .font(.system(size: 40, weight: .heavy))

                    if !entireEvolutionChain.isEmpty {
                        VStack(spacing: 10) {
                            Text("Evolutions")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            if entireEvolutionChain.count <= 4 {
                                HStack(spacing: 5) {
                                    evolutionChainContent
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 5) {
                                        evolutionChainContent
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    
                    HStack {
                        Image(systemName: pokemon.discovered ? "checkmark.circle.fill" : "lock.fill")
                        Text(pokemon.discovered ? "In Collection (x\(pokemon.count))" : "Not Caught Yet")
                    }
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(pokemon.discovered ? .green : .secondary)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background((pokemon.discovered ? Color.green : Color.gray).opacity(0.15))
                    .clipShape(Capsule())

                    if isDebugMode {
                        Button(action: {
                            StorageManager.shared.incrementPokemon(id: pokemon.id)
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .padding(.leading, 5)
                    }
                    
                    if nextEvolution != nil {
                        Text(canEvolve ? "Ready to Evolve!" : "Collect \(evolutionCost) to Evolve")
                            .font(.caption).bold()
                            .foregroundColor(canEvolve ? .blue : .gray)
                    }
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
            .padding(.bottom, 40)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if nextEvolution != nil {
                    Button("Evolve") { showEvolutionScreen = true }
                        .disabled(!canEvolve)
                        .fontWeight(.bold)
                }
            }
        }
        .task { await fetchFullData() }
        .sheet(isPresented: $showEvolutionScreen) {
            if let nextEvo = nextEvolution {
                EvolutionView(currentPokemon: pokemon, targetPokemon: nextEvo, cost: evolutionCost)
            }
        }
    }
    
    var evolutionChainContent: some View {
        ForEach(Array(entireEvolutionChain.enumerated()), id: \.element.id) { index, member in
            HStack(spacing: 0) {
                if member.id == pokemon.id {
                    VStack {
                        AsyncImage(url: member.imageURL) { img in
                            img.image?.resizable().scaledToFit()
                        }
                        .frame(width: 50, height: 50)
                    }
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                } else {
                    NavigationLink(destination: PokemonDetailView(pokemon: resolvePokemon(for: member))) {
                        VStack {
                            AsyncImage(url: member.imageURL) { img in
                                img.image?.resizable().scaledToFit()
                            }
                            .frame(width: 50, height: 50)
                            .saturation(0.0)
                        }
                        .padding(8)
                        .background(Color.clear)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if index < entireEvolutionChain.count - 1 {
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundColor(.gray.opacity(0.5))
                        .padding(.horizontal, 5)
                }
            }
        }
    }
    
    var canEvolve: Bool { return pokemon.count >= evolutionCost }
    
    var rarityInfo: (title: String, color: Color) {
        guard let s = species else { return ("", .gray) }
        if s.is_mythical { return ("MYTHICAL", .pink) }
        if s.is_legendary { return ("LEGENDARY", .yellow) }
        if s.capture_rate < 50 { return ("EPIC", .purple)}
        if s.capture_rate < 80 { return ("VERY RARE", .indigo) }
        if s.capture_rate < 135 { return ("RARE", .blue) }
        return ("COMMON", .mint)
    }
    
    func resolvePokemon(for target: EvolutionTarget) -> SavedPokemon {
        let context = StorageManager.shared.context
        let targetID = target.id
        let descriptor = FetchDescriptor<SavedPokemon>(predicate: #Predicate { $0.id == targetID })
        
        if let found = try? context.fetch(descriptor).first {
            return found
        }
        return SavedPokemon(id: target.id, name: target.name, spriteURLString: target.imageURL.absoluteString, count: 0)
    }
    
    func fetchFullData() async {
        do {
            let (data, _) = try await URLSession.shared.data(from: pokemon.detailURL)
            self.details = try JSONDecoder().decode(PokemonDetail.self, from: data)
            if let url = URL(string: details!.species.url) {
                let (speciesData, _) = try await URLSession.shared.data(from: url)
                self.species = try JSONDecoder().decode(PokemonSpecies.self, from: speciesData)
                await fetchEvolutionChain(url: species!.evolution_chain.url)
            }
            isLoading = false
        } catch { isLoading = false }
    }
    
    func fetchEvolutionChain(url: String) async {
        guard let url = URL(string: url) else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let chainData = try JSONDecoder().decode(EvolutionChainResponse.self, from: data)
            if let next = findNextEvolution(chain: chainData.chain, currentName: pokemon.name) {
                self.nextEvolution = next
            }
            var chainList: [EvolutionTarget] = []
            flattenChain(chain: chainData.chain, list: &chainList)
            self.entireEvolutionChain = chainList
        } catch { }
    }
    
    func flattenChain(chain: ChainLink, list: inout [EvolutionTarget]) {
        let id = extractID(from: chain.species.url)
        list.append(EvolutionTarget(name: chain.species.name, id: id))
        for child in chain.evolves_to { flattenChain(chain: child, list: &list) }
    }
    
    func findNextEvolution(chain: ChainLink, currentName: String) -> EvolutionTarget? {
        if chain.species.name == currentName {
            if let firstChild = chain.evolves_to.first {
                return EvolutionTarget(name: firstChild.species.name, id: extractID(from: firstChild.species.url))
            }
            return nil
        }
        for child in chain.evolves_to {
            if let found = findNextEvolution(chain: child, currentName: currentName) { return found }
        }
        return nil
    }
    
    func extractID(from url: String) -> Int {
        let clean = url.dropLast()
        return Int(clean.components(separatedBy: "/").last ?? "0") ?? 0
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

struct EvolutionView: View {
    let currentPokemon: SavedPokemon
    let targetPokemon: EvolutionTarget
    let cost: Int
    @Environment(\.dismiss) var dismiss
    @State private var evolutionStage: EvolutionStage = .confirmation
    enum EvolutionStage { case confirmation, success }
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            if evolutionStage == .confirmation { confirmationView } else { successView }
        }
    }
    
    var confirmationView: some View {
        VStack(spacing: 30) {
            Text("Evolution Chamber").font(.headline).padding(.top, 20)
            Spacer()
            HStack(spacing: 20) {
                VStack {
                    AsyncImage(url: currentPokemon.imageURL) { $0.image?.resizable().scaledToFit() }
                        .frame(width: 100, height: 100)
                    Text(currentPokemon.name.capitalized).bold()
                }
                Image(systemName: "arrow.right").font(.title).foregroundColor(.gray)
                VStack {
                    AsyncImage(url: targetPokemon.imageURL) { image in image.resizable().scaledToFit() } placeholder: {
                        Image(systemName: "questionmark.circle.fill").resizable().scaledToFit().foregroundColor(.gray)
                    }
                    .frame(width: 120, height: 120)
                    .blur(radius: 5)
                    .overlay(Text("?").font(.largeTitle).bold().foregroundColor(.white))
                    Text(targetPokemon.name.capitalized).bold().foregroundColor(.blue)
                }
            }
            Text("Requires \(cost) \(currentPokemon.name.capitalized)s")
                .font(.headline).foregroundColor(.red).padding()
                .background(Color.red.opacity(0.1)).cornerRadius(10)
            Spacer()
            Button(action: performEvolution) {
                Text("EVOLVE NOW").font(.title3).bold().frame(maxWidth: .infinity).padding()
                    .background(Color.blue).foregroundColor(.white).cornerRadius(15)
            }.padding()
        }.padding()
    }
    
    var successView: some View {
        VStack(spacing: 20) {
            Text("GOTCHA!").font(.system(size: 50, weight: .heavy)).foregroundColor(.yellow)
                .shadow(color: .orange, radius: 2).scaleEffect(1.1).padding(.top, 50)
            Spacer()
            ZStack {
                Circle().fill(Color.yellow.opacity(0.3)).frame(width: 250, height: 250).blur(radius: 20)
                AsyncImage(url: targetPokemon.imageURL) { image in image.resizable().scaledToFit() } placeholder: { ProgressView() }
                    .frame(width: 200, height: 200)
            }
            Text("You obtained \(targetPokemon.name.capitalized)!").font(.title2).bold().foregroundColor(.primary)
            Spacer()
            Button(action: { dismiss() }) {
                Text("Collect & Close").font(.headline).frame(maxWidth: .infinity).padding()
                    .background(Color.green).foregroundColor(.white).cornerRadius(15)
            }.padding()
        }
    }
    
    func performEvolution() {
        for _ in 0..<cost { StorageManager.shared.decrementPokemon(id: currentPokemon.id) }
        StorageManager.shared.addPokemon(id: targetPokemon.id, name: targetPokemon.name, imageURL: targetPokemon.imageURL.absoluteString)
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()
            
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
        }
        withAnimation { evolutionStage = .success }
    }
}

struct PokemonDetail: Codable { let stats: [StatEntry]; let species: SpeciesReference }
struct SpeciesReference: Codable { let url: String }
struct PokemonSpecies: Codable { let is_legendary: Bool; let is_mythical: Bool; let capture_rate: Int; let evolution_chain: EvolutionChainReference }
struct EvolutionChainReference: Codable { let url: String }
struct EvolutionChainResponse: Codable { let chain: ChainLink }
struct ChainLink: Codable { let species: SpeciesName; let evolves_to: [ChainLink] }
struct SpeciesName: Codable { let name: String; let url: String }
struct EvolutionTarget {
    let name: String; let id: Int
    var imageURL: URL { URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/\(id).png")! }
}
struct StatEntry: Codable, Identifiable { let base_stat: Int; let stat: StatName; var id: String { stat.name } }
struct StatName: Codable { let name: String }
