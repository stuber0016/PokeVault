import SwiftUI

struct PackOpeningView: View {
    @Environment(\.dismiss) var dismiss
    
    let packImageName: String
    
    // State
    @State private var tapCount = 0
    @State private var isOpened = false
    @State private var scale: CGFloat = 1.0
    
    // The cards we "found" from the DB
    @State private var openedPokemons: [Pokemon] = []
    
    var body: some View {
        VStack {
            if isOpened {
                // MARK: - Reveal Phase
                ScrollView {
                    VStack(spacing: 20) {
                        Text("You found \(openedPokemons.count) Cards!")
                            .font(.headline)
                            .padding(.top)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                            ForEach(openedPokemons) { pokemon in
                                VStack {
                                    // Use the cached image URL from the DB
                                    AsyncImage(url: pokemon.spriteURL) { phase in
                                        if let image = phase.image {
                                            image.resizable().aspectRatio(contentMode: .fit)
                                        } else {
                                            Color.gray.opacity(0.1) // Placeholder while loading
                                        }
                                    }
                                    .frame(width: 80, height: 80)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(radius: 2)
                                    
                                    Text(pokemon.name.capitalized)
                                        .font(.caption)
                                        .bold()
                                        .multilineTextAlignment(.center)
                                }
                            }
                        }
                        .padding()
                        
                        Button("Done") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                
            } else {
                // MARK: - Tapping Phase
                VStack(spacing: 40) {
                    Text(tapCount == 0 ? "Tap the pack 3 times!" : "\(3 - tapCount) more...")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Image(packImageName) // Or pass the specific pack name if you want it to match
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .scaleEffect(scale)
                        .rotationEffect(.degrees(tapCount == 0 ? 0 : Double.random(in: -5...5)))
                        .onTapGesture {
                            handleTap()
                        }
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: scale)
                }
            }
        }
        .navigationTitle("Open Pack")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func handleTap() {
        guard tapCount < 3 else { return }
        
        scale = 0.9
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { scale = 1.0 }
        
        tapCount += 1
        
        if tapCount == 3 {
            generatePackContent()
            withAnimation {
                isOpened = true
            }
        }
    }
    
    private func generatePackContent() {
        let numberOfCards = Int.random(in: 2...5)
        var newCards: [Pokemon] = []
        
        for _ in 0..<numberOfCards {
            // 1. Pick a random ID from the range Coder A seeded
            let randomId = Int.random(in: 1...500)
            
            // 2. Increment it in the DB and get the real data back
            if let pokemon = StorageManager.shared.incrementPokemon(id: randomId) {
                newCards.append(pokemon)
            }
        }
        
        self.openedPokemons = newCards
    }
}
