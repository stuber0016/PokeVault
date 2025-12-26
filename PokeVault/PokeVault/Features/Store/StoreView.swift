import SwiftUI

struct StoreView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Daily Packs")
                    .font(.title2)
                    .bold()
                    .padding(.horizontal)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    
                    NavigationLink(destination: PackOpeningView(packImageName: "pack_standard")) {
                        PackItem(title: "Standard Pack", imageName: "pack_standard", color: .blue)
                    }
                    
                    NavigationLink(destination: PackOpeningView(packImageName: "pack_gold")) {
                        PackItem(title: "Gold Pack", imageName: "pack_gold", color: .yellow)
                    }
                    
                    NavigationLink(destination: PackOpeningView(packImageName: "pack_retro")) {
                        PackItem(title: "Retro Pack", imageName: "pack_retro", color: .purple)
                    }
                    
                    NavigationLink(destination: PackOpeningView(packImageName: "pack_mystery")) {
                        PackItem(title: "Mystery Pack", imageName: "pack_mystery", color: .black)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Store")
    }
}

// Reusable Pack Component
// Helper View for the Pack Card
struct PackItem: View {
    let title: String
    let imageName: String // <--- Changed this
    let color: Color
    
    var body: some View {
        VStack {
            // Load from Assets instead of System
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 100) // Slightly taller for real art
                .shadow(radius: 5)
                .padding(.top, 10)
            
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .background(color.gradient)
        .cornerRadius(20)
        .shadow(color: color.opacity(0.4), radius: 10, x: 0, y: 5)
    }
}
