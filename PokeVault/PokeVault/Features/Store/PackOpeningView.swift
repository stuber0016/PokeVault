import SwiftUI

struct PackOpeningView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var currencyManager = CurrencyManager.shared
    
    let packImageName: String
    let price: Int
    
    @State private var tapCount = 0
    @State private var isOpened = false
    @State private var scale: CGFloat = 1.0
    @State private var rotationAngle: Double = 0.0
    @State private var openedPokemons: [Pokemon] = []
    @State private var showInsufficientFunds = false
    
    var body: some View {
        VStack {
            if isOpened {
                ScrollView {
                    VStack(spacing: 20) {
                        Text("You found \(openedPokemons.count) Cards!")
                            .font(.headline)
                            .padding(.top)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                            ForEach(openedPokemons) { pokemon in
                                VStack {
                                    AsyncImage(url: pokemon.spriteURL) { phase in
                                        if let image = phase.image {
                                            image.resizable().aspectRatio(contentMode: .fit)
                                        } else {
                                            Color.gray.opacity(0.1)
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
                        
                        Button("Done") { dismiss() }
                        .buttonStyle(.borderedProminent)
                        .padding()
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                
            } else {
                VStack(spacing: 40) {
                    Text(tapCount == 0 ? "Tap 3 times to open!" : "\(3 - tapCount) more...")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Image(packImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .scaleEffect(scale)
                        .rotationEffect(.degrees(rotationAngle))
                        .onTapGesture { handleTap() }
                        .animation(.spring(response: 0.3, dampingFraction: 0.4, blendDuration: 0), value: scale)
                        .animation(.linear(duration: 0.1), value: rotationAngle)
                }
            }
        }
        .navigationTitle("Open Pack")
        .alert("Not Enough Coins", isPresented: $showInsufficientFunds) {
            Button("OK", role: .cancel) { dismiss() }
        } message: {
            Text("You need \(price) coins. Go walk some more!")
        }
    }
    
    private func handleTap() {
        if tapCount == 0 && currencyManager.coins < price {
            showInsufficientFunds = true
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }
        
        guard tapCount < 3 else { return }
        
        scale = 0.85
        rotationAngle = Double.random(in: -10...10)
        
        if tapCount < 2 {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } else {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            scale = 1.0
            rotationAngle = 0.0
        }
        
        tapCount += 1
        
        if tapCount == 3 {
            currencyManager.coins -= price
            generatePackContent()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                withAnimation { isOpened = true }
            }
        }
    }
    
    private func generatePackContent() {
        let numberOfCards = Int.random(in: 2...5)
        var newCards: [Pokemon] = []
        for _ in 0..<numberOfCards {
            let randomId = Int.random(in: 1...1350)
            if let pokemon = StorageManager.shared.incrementPokemon(id: randomId) {
                newCards.append(pokemon)
            }
        }
        self.openedPokemons = newCards
    }
}
