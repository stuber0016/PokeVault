import SwiftUI
import SwiftData

struct InventoryListView: View {
    @Query(filter: #Predicate<SavedPokemon> { $0.count > 0 }, sort: \SavedPokemon.id)
    private var savedPokemons: [SavedPokemon]
    
    @EnvironmentObject var p2pManager: P2PManager
    
    // UI State
    @State private var isSelectionMode = false
    @State private var searchText = ""
    @State private var showTradeSheet = false
    
    // Profile State
    @State private var showProfileSheet = false
    @AppStorage("userAvatar") private var currentUserAvatar = "avatar_1"
    
    // The Cart: [PokemonID : QuantitySelected]
    @State private var selectedQuantities: [Int: Int] = [:]

    var body: some View {
        List {
            ForEach(filteredPokemons) { saved in
                let pokemon = Pokemon(saved: saved)
                let isSelected = selectedQuantities.keys.contains(pokemon.id)
                
                ZStack {
                    // LAYER 1: The Interaction Layer (Background)
                    // We put this BEHIND the content so it catches taps on empty space,
                    // but allows the Stepper Buttons (which are on top) to still work.
                    if isSelectionMode {
                        // Selection Handler
                        // Use a nearly invisible color + contentShape to ensure it catches taps
                        Color.white.opacity(0.001)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                toggleSelection(for: pokemon)
                            }
                    } else {
                        // Navigation Handler
                        // Hidden link that triggers when the row is tapped
                        NavigationLink(destination: PokemonDetailView(pokemon: saved)) {
                            EmptyView()
                        }
                        .opacity(0)
                    }
                    
                    // LAYER 2: The Visual Content (Foreground)
                    // Kept as the last item to be visually on top.
                    // This ensures the Stepper Buttons receive touches first.
                    rowContent(saved: saved, pokemon: pokemon, isSelected: isSelected)
                }
                .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 10))
            }
        }
        .navigationTitle("Inventory")
        .searchable(text: $searchText, prompt: "Search your cards")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showProfileSheet = true
                } label: {
                    Image(currentUserAvatar)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.primary.opacity(0.2), lineWidth: 1))
                }
            }
        }
        // MARK: - Floating Action Buttons
        .overlay(alignment: .bottom) {
            ZStack {
                if isSelectionMode {
                    HStack(spacing: 20) {
                        Button {
                            withAnimation {
                                isSelectionMode = false
                                selectedQuantities = [:]
                            }
                        } label: {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                Text("Cancel")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(30)
                            .shadow(radius: 5)
                        }
                        
                        if !selectedQuantities.isEmpty {
                            Button(action: prepareTrade) {
                                HStack {
                                    Image(systemName: "paperplane.fill")
                                    Text("Send \(totalItemsInCart)")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(30)
                                .shadow(radius: 5)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                } else {
                    Button {
                        withAnimation {
                            isSelectionMode = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Select")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(30)
                        .shadow(radius: 5)
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $showTradeSheet) {
            TradeSheetView()
        }
        .sheet(isPresented: $showProfileSheet) {
            ProfileView()
        }
        .overlay {
            if p2pManager.showReceivedAlert {
                TradeSuccessView(message: p2pManager.receivedAlertMessage) {
                    p2pManager.showReceivedAlert = false
                }
                .zIndex(100)
            }
        }
        .onChange(of: p2pManager.shouldCloseTradeSheet) { oldValue, newValue in
            if newValue {
                showTradeSheet = false
                withAnimation {
                    isSelectionMode = false
                    selectedQuantities = [:]
                }
                p2pManager.shouldCloseTradeSheet = false
            }
        }
        .onAppear {
            p2pManager.startHosting()
        }
        .onDisappear {
            p2pManager.stopHosting()
        }
    }
    
    // MARK: - Row Content Helper
    @ViewBuilder
    func rowContent(saved: SavedPokemon, pokemon: Pokemon, isSelected: Bool) -> some View {
        HStack {
            if isSelectionMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title2)
                    .transition(.scale.combined(with: .opacity))
            }
            
            AsyncImage(url: pokemon.spriteURL) { i in i.resizable() } placeholder: { Color.gray }
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading) {
                Text(pokemon.name).font(.headline)
                if !isSelectionMode {
                    Text("Owned: \(saved.count)").font(.caption).foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            if isSelectionMode && isSelected {
                HStack {
                    Button("-") {
                        if let current = selectedQuantities[pokemon.id], current > 1 {
                            selectedQuantities[pokemon.id] = current - 1
                        } else {
                            selectedQuantities.removeValue(forKey: pokemon.id)
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Text("\(selectedQuantities[pokemon.id] ?? 0)")
                        .frame(minWidth: 20)
                    
                    Button("+") {
                        let current = selectedQuantities[pokemon.id] ?? 0
                        if current < saved.count {
                            selectedQuantities[pokemon.id] = current + 1
                        }
                    }
                    .buttonStyle(.bordered)
                }
            } else if !isSelectionMode {
                Text("x\(saved.count)")
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Helpers
    
    var filteredPokemons: [SavedPokemon] {
        if searchText.isEmpty { return savedPokemons }
        return savedPokemons.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var totalItemsInCart: Int {
        selectedQuantities.values.reduce(0, +)
    }
    
    func toggleSelection(for pokemon: Pokemon) {
        if selectedQuantities.keys.contains(pokemon.id) {
            selectedQuantities.removeValue(forKey: pokemon.id)
        } else {
            selectedQuantities[pokemon.id] = 1
        }
    }
    
    func prepareTrade() {
        var itemsToSend: [TradeItem] = []
        for (id, qty) in selectedQuantities {
            if let saved = savedPokemons.first(where: { $0.id == id }) {
                itemsToSend.append(TradeItem(
                    pokemonID: id,
                    name: saved.name,
                    spriteURL: saved.spriteURLString,
                    quantity: qty
                ))
            }
        }
        p2pManager.batchToSend = itemsToSend
        showTradeSheet = true
    }
}
