//
//  TradeBatch.swift
//  PokeVault
//
//  Created by Samuel Luis Štúber on 27.12.2025.
//


import Foundation

struct TradeBatch: Codable {
    let items: [TradeItem]
}

struct TradeItem: Codable, Identifiable {
    var id: Int { pokemonID } // Conformance for Identifiable
    let pokemonID: Int
    let name: String
    let spriteURL: String
    let quantity: Int
}