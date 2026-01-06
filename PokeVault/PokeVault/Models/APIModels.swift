//
//  APIModels.swift
//  PokeVault
//
//  Created by Petr Herčko on 26.12.2025.
//

import Foundation

struct PokemonListResponse: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [PokemonListEntry]
}

struct PokemonListEntry: Codable {
    let name: String
    let url: String
    
    var id: Int {
        let urlString = url
        
        var cleanString = urlString
        if cleanString.hasSuffix("/") {
            cleanString.removeLast()
        }
        
        if let lastPart = cleanString.components(separatedBy: "/").last,
           let idNumber = Int(lastPart) {
            return idNumber
        }
        
        print("⚠️ FAILED TO PARSE ID FROM: \(url)")
        return 0
    }
}
