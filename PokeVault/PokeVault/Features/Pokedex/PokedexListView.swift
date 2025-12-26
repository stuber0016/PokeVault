//
//  PokedexListView.swift
//  PokeVault
//
//  Created by Samuel Luis Štúber on 26.12.2025.
//


import SwiftUI

struct PokedexListView: View {
    var body: some View {
        VStack {
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .padding()
            Text("Pokedex Under Construction")
                .foregroundColor(.gray)
            Text("(Waiting for Coder A)")
                .font(.caption)
        }
        .navigationTitle("Pokedex")
    }
}
