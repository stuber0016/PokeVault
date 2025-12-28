//
//  RootView.swift
//  PokeVault
//
//  Created by Petr Herčko on 28.12.2025.
//


import SwiftUI
import SwiftData

struct RootView: View {
    @State private var isAppReady = false
    
    var body: some View {
        Group {
            if isAppReady {
                MainTabView()
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "globe.americas.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Initializing Pokedex...")
                        .font(.headline)
                    
                    ProgressView()
                }
            }
        }
        .task {
            await DataSeeder.shared.seedDatabase()
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            withAnimation {
                isAppReady = true
            }
        }
    }
}
