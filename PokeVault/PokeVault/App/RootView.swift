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
    @State private var rotate = false

    
    var body: some View {
        Group {
            if isAppReady {
                MainTabView()
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                                .font(.system(size: 80))
                                .foregroundColor(.blue)
                                .rotationEffect(.degrees(rotate ? 360 : 0))
                                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: rotate)
                                .onAppear {
                                    rotate = true
                                }
                    
                    Text("Initializing Pokedex...")
                        .font(.headline)
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

#Preview {
    RootView()
}
