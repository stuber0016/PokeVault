import SwiftUI

struct StoreView: View {
    @StateObject private var healthManager = HealthManager.shared
    @StateObject private var currencyManager = CurrencyManager.shared
    @State private var justEarned: Int = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // MARK: - Wallet Header
                VStack(spacing: 15) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Balance")
                                .font(.caption)
                                .foregroundColor(.gray)
                            HStack {
                                Image(systemName: "centsign.circle.fill")
                                    .foregroundColor(.yellow)
                                Text("\(currencyManager.coins)")
                                    .font(.title)
                                    .bold()
                            }
                        }
                        Spacer()
                        
                        // Claim Button
                        Button(action: claimCoins) {
                            VStack {
                                Text("Walked: \(healthManager.currentStepCount)")
                                    .font(.caption2)
                                Text(justEarned > 0 ? "+\(justEarned) Coins!" : "Claim Steps")
                                    .font(.headline)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(15)
                }
                .padding()
                
                Text("Daily Packs")
                    .font(.title2)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                // MARK: - Pack Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    
                    NavigationLink(destination: PackOpeningView(packImageName: "pack_standard", price: 50)) {
                        PackItem(title: "Standard Pack", imageName: "pack_standard", color: .blue, price: 50)
                    }
                    
                    NavigationLink(destination: PackOpeningView(packImageName: "pack_gold", price: 100)) {
                        PackItem(title: "Gold Pack", imageName: "pack_gold", color: .yellow, price: 100)
                    }
                    
                    NavigationLink(destination: PackOpeningView(packImageName: "pack_retro", price: 200)) {
                        PackItem(title: "Retro Pack", imageName: "pack_retro", color: .purple, price: 200)
                    }
                    
                    NavigationLink(destination: PackOpeningView(packImageName: "pack_mystery", price: 500)) {
                        PackItem(title: "Mystery Pack", imageName: "pack_mystery", color: .black, price: 500)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Store")
        .onAppear {
            healthManager.requestAuthorization()
            healthManager.fetchTodaySteps()
        }
    }
    
    func claimCoins() {
        healthManager.fetchTodaySteps()
        let earned = currencyManager.claimSteps(currentHealthKitSteps: healthManager.currentStepCount)
        if earned > 0 {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            withAnimation { justEarned = earned }
            // Hide the "+50 Coins" text after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { justEarned = 0 }
            }
        }
        else {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
}

// Updated PackItem to show price
struct PackItem: View {
    let title: String
    let imageName: String
    let color: Color
    let price: Int
    
    var body: some View {
        VStack {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 100)
                .shadow(radius: 5)
                .padding(.top, 10)
            
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            
            HStack(spacing: 4) {
                Image(systemName: "centsign.circle.fill")
                    .font(.caption)
                Text("\(price)")
                    .font(.caption)
                    .bold()
            }
            .padding(6)
            .background(Color.black.opacity(0.3))
            .cornerRadius(10)
            .foregroundStyle(.white)
            .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 190) // Slightly taller
        .background(color.gradient)
        .cornerRadius(20)
        .shadow(color: color.opacity(0.4), radius: 10, x: 0, y: 5)
    }
}
