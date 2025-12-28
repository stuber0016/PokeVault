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
                
                HStack {
                    // 1. Selection Checkbox (Only in Selection Mode)
                    if isSelectionMode {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isSelected ? .blue : .gray)
                            .font(.title2)
                            .onTapGesture {
                                toggleSelection(for: pokemon)
                            }
                    }
                    
                    // 2. Pokemon Info
                    AsyncImage(url: pokemon.spriteURL) { i in i.resizable() } placeholder: { Color.gray }
                        .frame(width: 50, height: 50)
                    
                    VStack(alignment: .leading) {
                        Text(pokemon.name).font(.headline)
                        if !isSelectionMode {
                            Text("Owned: \(saved.count)").font(.caption).foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    // 3. Right Side Logic
                    if isSelectionMode && isSelected {
                        // SHOPPING CART STEPPER
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
                        // Standard View: Just show count
                        Text("x\(saved.count)")
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .contentShape(Rectangle()) // Makes whole row tappable
                .onTapGesture {
                    if isSelectionMode { toggleSelection(for: pokemon) }
                }
            }
        }
        .navigationTitle("Inventory")
        .toolbar {
            // ONLY Profile button remains in toolbar now
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
                    // SELECTION MODE: Two Buttons (Cancel & Send)
                    HStack(spacing: 20) {
                        // 1. Cancel Button (Red, Left)
                        Button {
                            withAnimation {
                                isSelectionMode = false
                                selectedQuantities = [:] // Clear selection
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
                        
                        // 2. Send Button (Blue, Right) - Only if items selected
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
                    // NORMAL MODE: Select Button (Green)
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
            .padding(.bottom, 20) // Lift off the bottom edge
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
        // MARK: - Auto Close & Reset Logic (UPDATED)
        .onChange(of: p2pManager.shouldCloseTradeSheet) { oldValue, newValue in
            if newValue {
                showTradeSheet = false
                
                // NEW: Reset the UI to default state (Exit selection mode)
                withAnimation {
                    isSelectionMode = false
                    selectedQuantities = [:] // Clear the cart
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
                let item = TradeItem(
                    pokemonID: id,
                    name: saved.name,
                    spriteURL: saved.spriteURLString,
                    quantity: qty
                )
                itemsToSend.append(item)
            }
        }
        
        p2pManager.batchToSend = itemsToSend
        showTradeSheet = true
    }
}
