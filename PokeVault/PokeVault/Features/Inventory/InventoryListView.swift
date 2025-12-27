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
                        // Shows:  -  3  +
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
                                if current < saved.count { // Don't allow sending more than you have
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
            ToolbarItem(placement: .topBarTrailing) {
                Button(isSelectionMode ? "Cancel" : "Select") {
                    isSelectionMode.toggle()
                    selectedQuantities = [:] // Clear cart on toggle
                }
            }
        }
        // Floating "Send" Button
        .overlay(alignment: .bottom) {
            if isSelectionMode && !selectedQuantities.isEmpty {
                Button(action: prepareTrade) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                        Text("Send \(totalItemsInCart) Cards")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(30)
                    .shadow(radius: 5)
                }
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showTradeSheet) {
            // We reuse the Trade Sheet, but updated to support batch
            TradeSheetView()
        }
        .overlay {
            if p2pManager.showReceivedAlert {
                TradeSuccessView(message: p2pManager.receivedAlertMessage) {
                    // Dismiss action
                    p2pManager.showReceivedAlert = false
                }
                .zIndex(100) // Ensure it sits on top of everything
            }
        }
        .onChange(of: p2pManager.shouldCloseTradeSheet) { oldValue, newValue in
            if newValue {
                showTradeSheet = false
                p2pManager.shouldCloseTradeSheet = false // Reset logic
            }
        }
        .onAppear {
            // Crucial: Start advertising so the other phone can find us!
            p2pManager.startHosting()
        }
        .onDisappear {
            // Stop advertising when we leave (e.g. background or other tab)
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
        // Convert the "Cart" dictionary into TradeItems
        var itemsToSend: [TradeItem] = []
        
        for (id, qty) in selectedQuantities {
            // Find the original data to get Name/Sprite (inefficient but safe for 150 items)
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
        
        // Load into Manager and open sheet
        p2pManager.batchToSend = itemsToSend
        showTradeSheet = true
    }
}

