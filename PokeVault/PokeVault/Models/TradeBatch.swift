//
//  TradeBatch.swift
//  PokeVault
//
//  Created by Samuel Luis Štúber on 27.12.2025.
//


import Foundation

struct TradeBatch: Codable {
    let items: [TradeItem]
    let senderName: String
}

struct TradeItem: Codable, Identifiable {
    var id: Int { pokemonID }
    let pokemonID: Int
    let name: String
    let spriteURL: String
    let quantity: Int
}
